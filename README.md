# PS-Recover

**Windows Depolama Kurtarma ve Flash Bellek Onarım Motoru**

PS-Recover, Windows platformunda harici depolama aygıtları, USB flash bellekler ve dahili diskler için geliştirilmiş, harici bağımlılık gerektirmeyen (zero-dependency) bir dosya kurtarma ve tanılama aracıdır.

Sistem, PowerShell ortamında tek komutla (`recover`) veya uzaktan yürütme (`iex`) protokolüyle doğrudan bellek üzerinden çalıştırılabilir.

---

## Hızlı Başlangıç

Kurulum veya bağımlılık yapılandırması gerekmeksizin, Windows PowerShell (5.1 veya 7+) üzerinden doğrudan çalıştırılabilir:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/recover.ps1 | iex
```

### Kalıcı Profil Entegrasyonu
Aracı PowerShell ortamına kalıcı bir fonksiyon olarak kaydetmek için:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/install.ps1 | iex
```

Kurulum tamamlandıktan sonra herhangi bir terminal oturumunda `recover` komutu doğrudan çağrılabilir.

---

## Temel Kabiliyetler

### 1. Donanım ve Mantıksal Sürücü Taraması
- Windows Storage Management API (`Get-Volume`, `Get-Partition`, `Get-Disk`) ve CIM/WMI geri dönüş mekanizması üzerinden bağlı tüm depolama aygıtlarını listeler.
- Fiziksel disk modeli, birim etiketi, veri yolu türü (USB, NVMe, SATA), dosya sistemi (NTFS, FAT32, exFAT), toplam kapasite ve boş alan metriklerini sunar.
- Aygıt düzeyindeki salt okunur (read-only) durumunu ve işletim sistemi korumalı birimleri otomatik olarak sınıflandırır.

### 2. Dayanıklı Veri Kurtarma Motoru
- Seçilen aygıttaki dosyaları kaynak dizin hiyerarşisini koruyarak `[Desktop]\recovered\Kurtarma_<Harf>_<ZamanDamgası>` hedefine aktarır.
- Okunamayan veya bozuk sektör içeren dosyalar durumunda işlem kesintiye uğramaz; akış tabanlı okuma denemesi yapılır ve sonuç hata günlüğüne işlenerek işlem sürdürülür.
- Çakışma önleyici zaman damgası ve benzersiz oturum dizinleri sayesinde önceki kurtarma verileri korunur.

### 3. Kısayol Zararlısı Temizliği ve Öznitelik Normalizasyonu
- USB belleklerde sık karşılaşılan klasör gizleme ve `.lnk` / `.vbs` kısayol zararlılarının gizlediği verileri tespit eder.
- Kurtarılan dosyalardaki kısıtlayıcı dosya sistemi özniteliklerini (`ReadOnly`, `Hidden`, `System`) otomatik olarak `Normal` durumuna getirir.

### 4. Çok Kriterli Dosya Filtreleme
- Tam disk imajı yedeğinin yanı sıra belirli dosya kategorilerine göre seçici kurtarma yapılabilir:
  - Belgeler: PDF, DOCX, XLSX, PPTX, TXT, CSV, RTF
  - Medya: JPG, PNG, RAW, CR2, NEF, HEIC, MP4, MKV, WAV, FLAC
  - Arşivler: ZIP, RAR, 7Z, TAR, GZ, ISO
  - Geliştirme: PY, JS, TS, CS, CPP, SQL, JSON
  - Kullanıcı tanımlı uzantı listeleri

### 5. Salt Okunur (Yazma Korumalı) Flash Bellek Tanılama ve Onarım Hattı
Yazma koruması bulunan aygıtlar için güvenlik öncelikli bir onarım süreci yürütür:
1. **Ön Güvenlik Yedeklemesi:** Kontrolcüye stres bindirebilecek onarım adımlarından önce bellekteki tüm okunabilir veriler masaüstüne yedeklenir.
2. **Diskpart Öznitelik Sıfırlama:** Fiziksel disk ve mantıksal birim düzeyindeki `readonly` bayrakları temizlenir.
3. **Storage API Konfigürasyonu:** `Set-Disk -IsReadOnly $false` çağrısı ile çekirdek düzeyindeki koruma bayrağı kaldırılır.
4. **Kayıt Defteri Denetimi:** `HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect` anahtarı sıfırlanır.
5. **Dosya Sistemi Onarımı:** Chkdsk entegrasyonuyla dirty-bit ve indeks tutarsızlıkları düzeltilir.
6. **Donanımsal Denetim ve Teşhis:** Aygıta test verisi yazılarak kontrolcünün durumu doğrulanır. Yazılımsal kilitler kalkmasına rağmen yazma reddediliyorsa, bellek yongalarının yıpranma korumasına (NAND hardware ROM mode) geçtiği net bir şekilde raporlanır.

### 6. Raporlama ve Denetim İzi
- İşlem tamamlandığında kurtarma oturumunun metrikleri terminale basılır.
- Oturum klasörü içerisinde her bir dosyanın boyutunu, bağıl yolunu ve kurtarma durumunu listeleyen UTF-8 kodlamalı `kurtarma_raporu.txt` dosyası üretilir.

---

## Terminal Arayüzü

```text
 ===========================================================================
   ____  ____        ____                                          
  |  _ \/ ___|      |  _ \ ___  ___ _____   _____ _ __ _   _       
  | |_) \___ \ _____| |_) / _ \/ __/ _ \ \ / / _ \ '__| | | |      
  |  __/ ___) |_____|  _ <  __/ (_| (_) \ V /  __/ |  | |_| |      
  |_|   |____/      |_| \_\___|\___\___/ \_/ \___|_|   \__, |      
                                                        |___/       
       Windows Disk, USB & Flash Bellek Kurtarma Araci v1.0         
 ===========================================================================
 [i] Oturum Modu: YONETICI (ADMIN) - Tum diskpart ve kilit acma yetkileri aktif

 TAKILI DISKLER VE DEPOLAMA BIRIMLERI:
 ---------------------------------------------------------------------------------------------
 #    SURUCU MODEL / ETIKET           TUR                FS         TOPLAM   BOS ALAN  DURUM
 ---------------------------------------------------------------------------------------------
 [1]  C:     CT1000P3PSSD8            NVMe SSD (Dahili)  NTFS    930.26 GB  191.81 GB  [SISTEM DISKI]
 [2]  E:     YEDEK (Kingston DT 3.0)  USB Flash / Harici FAT32    29.80 GB   14.20 GB  [SALT OKUNUR / KILITLI]
 ---------------------------------------------------------------------------------------------
```

---

## Komut Parametreleri

| Parametre | Açıklama |
|---|---|
| `recover` | Etkileşimli ana menüyü başlatır. |
| `recover -List` | Takılı diskleri ve durumlarını tablo formatında listeler ve sonlanır. |
| `recover -Install` | Aracı geçerli PowerShell profil dosyasına kalıcı olarak kaydeder. |
| `recover -Uninstall` | Profil kaydını ve yerel çalışma dosyalarını sistemden temizler. |
| `recover -Help` | Parametre ve kullanım yardımını görüntüler. |

---

## Yazma Koruması Tanılama Modeli

Flash belleklerde salt okunur durum iki temel kaynaktan kaynaklanır:

| Kilit Türü | Mekanizma | Çözüm Yaklaşımı |
|---|---|---|
| **Yazılımsal Kilit** | Diskpart öznitelikleri, Windows Kayıt Defteri kısıtlamaları, dosya izinleri veya güvensiz çıkarma sonucu oluşan dosya sistemi `dirty bit` bayrağı. | PS-Recover tüm mantıksal katmanlardaki kilitleri temizler ve birimi yeniden yazılabilir hale getirir. |
| **Donanımsal Koruma (NAND Wear-Out)** | Bellek kontrolcüsü, aşınmış bellek blokları veya kritik bad-sector artışı tespit ettiğinde veri kaybını önlemek için kalıcı salt okunur (Hardware ROM) moduna geçer. | Donanımsal kilit geri döndürülemez. PS-Recover **önce tüm verileri masaüstüne kurtarır**, ardından durumu tespit ederek veri kaybı riskini ortadan kaldırır. |

---

## Test ve Doğrulama

Sanal depolama ortamında birim ve entegrasyon testlerini çalıştırmak için:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test-recovery.ps1
```

---

## Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynak olarak yayımlanmıştır.
