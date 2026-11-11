# PS-Recover

**Language / Dil / Sprache / Idioma:** [English](README.md) | [Türkçe](README.tr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

**Windows Depolama Kurtarma ve Flash Bellek Onarım Motoru**

PS-Recover, Windows platformunda harici depolama aygıtları, USB flash bellekler, SD kartlar ve dahili diskler için geliştirilmiş, harici bağımlılık gerektirmeyen (zero-dependency) bir dosya kurtarma, tanılama ve onarım aracıdır.

Sistem, PowerShell ortamında tek komutla doğrudan bellek üzerinden (`irm ... | iex`) veya kalıcı terminal komutu (`recover`) olarak çalıştırılabilir.

---

## Hızlı Başlangıç

### Doğrudan Bellekten Çalıştırma
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

## Çoklu Dil Desteği

PS-Recover, menüler, tablolar, günlükler, hata bildirimleri ve rapor dosyaları dahil olmak üzere tam iki dilli (Türkçe ve İngilizce) altyapıya sahiptir.

- **Komut Satırı Parametresi:** Başlangıçta dil belirtebilirsiniz:
  ```powershell
  recover -Lang tr    # Türkçe
  recover -Lang en    # İngilizce
  ```
- **Etkileşimli Dil Menüsü:** Ana menüde dilediğiniz an `[L]` tuşuna basarak Türkçe ve İngilizce arasında anında geçiş yapabilirsiniz.
- **Kalıcı Tercih:** Seçilen dil tercihi `~/.ps-recover/lang.conf` dosyasında saklanır ve sonraki oturumlarda otomatik olarak hatırlanır.
- **Sistem Dili Algılama:** Herhangi bir yapılandırma bulunmadığında sisteminizin Windows görüntüleme diline göre otomatik uyum sağlar.

---

## Temel Kabiliyetler

### 1. Donanım ve Mantıksal Sürücü Taraması
- Windows Storage Management API (`Get-Volume`, `Get-Partition`, `Get-Disk`) ve CIM/WMI geri dönüş mekanizması üzerinden bağlı tüm depolama aygıtlarını listeler.
- Fiziksel disk modeli, birim etiketi, veri yolu türü (USB, NVMe, SATA), dosya sistemi (NTFS, FAT32, exFAT), toplam kapasite ve boş alan metriklerini sunar.
- Aygıt düzeyindeki salt okunur (read-only) durumunu ve işletim sistemi korumalı birimleri otomatik olarak sınıflandırır.

### 2. Dayanıklı Veri Kurtarma Motoru
- Seçilen aygıttaki dosyaları kaynak dizin hiyerarşisini koruyarak `[Desktop]\recovered\Kurtarma_<Harf>_<ZamanDamgası>` hedefine aktarır.
- Okunamayan veya bozuk sektör içeren dosyalar durumunda işlem kesintiye uğramaz; akış tabanlı okuma denemesi yapılır ve sonuç hata günlüğüne işlenerek işlem sürdürülür.
- Kurtarılan dosyalardaki kısıtlayıcı dosya sistemi özniteliklerini (`ReadOnly`, `Hidden`, `System`) otomatik olarak `Normal` durumuna getirir.

### 3. Kısayol Zararlısı Temizliği ve Veri Kurtarma
- USB belleklerde sık karşılaşılan klasör gizleme ve `.lnk` / `.vbs` kısayol zararlılarının gizlediği verileri tespit eder.
- Zararlı kısayolları filtreleyerek arkasına gizlenmiş asıl verileri güvenli şekilde ayıklar.

### 4. Çok Kriterli Dosya Filtreleme
- Tam disk yedeğinin yanı sıra belirli dosya kategorilerine göre seçici kurtarma yapılabilir:
  - **Belgeler:** PDF, DOCX, XLSX, PPTX, TXT, CSV, RTF, ODT
  - **Fotoğraf ve Görseller:** JPG, PNG, GIF, BMP, RAW, CR2, NEF, HEIC, PSD
  - **Videolar:** MP4, MKV, AVI, MOV, WMV, FLV, WEBM
  - **Ses Dosyaları:** MP3, WAV, FLAC, AAC, M4A, OGG
  - **Arşivler:** ZIP, RAR, 7Z, TAR, GZ, ISO
  - **Geliştirme Dosyaları:** PY, JS, TS, HTML, CSS, CS, CPP, SQL, JSON
  - **Özel Uzantılar:** Kullanıcı tanımlı, virgülle ayrılmış uzantı listeleri

### 5. Salt Okunur (Yazma Korumalı) Flash Bellek Tanılama ve Onarım Hattı
Yazma koruması bulunan aygıtlar için güvenlik öncelikli bir onarım süreci yürütür:
1. **Ön Güvenlik Yedeklemesi:** Kontrolcüye stres bindirebilecek onarım adımlarından önce bellekteki tüm okunabilir veriler masaüstüne yedeklenir.
2. **Diskpart Öznitelik Sıfırlama:** Fiziksel disk ve mantıksal birim düzeyindeki `readonly` bayrakları temizlenir.
3. **Storage API Konfigürasyonu:** `Set-Disk -IsReadOnly $false` çağrısı ile çekirdek düzeyindeki koruma bayrağı kaldırılır.
4. **Kayıt Defteri Denetimi:** `HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect` anahtarı denetlenir ve sıfırlanır.
5. **Dosya Sistemi Onarımı:** Chkdsk entegrasyonuyla dirty-bit ve indeks tutarsızlıkları düzeltilir.
6. **Donanımsal Denetim ve Teşhis:** Aygıta test verisi yazılarak kontrolcünün durumu doğrulanır. Yazılımsal kilitler kalkmasına rağmen yazma reddediliyorsa, bellek yongalarının yıpranma korumasına (NAND hardware ROM mode) geçtiği net bir şekilde raporlanır.

### 6. Raporlama ve Denetim İzi
- İşlem tamamlandığında kurtarma oturumunun metrikleri terminale basılır.
- Oturum klasörü içerisinde her bir dosyanın boyutunu, bağıl yolunu ve kurtarma durumunu listeleyen UTF-8 kodlamalı `kurtarma_raporu.txt` (İngilizce modda `recovery_report.txt`) dosyası üretilir.

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
       Windows Disk, USB ve Flash Bellek Kurtarma Araci v1.0         
 ===========================================================================
 [i] Oturum Modu: YONETICI (ADMIN) - Tum diskpart ve kilit acma yetkileri aktif

 TAKILI DISKLER VE DEPOLAMA BIRIMLERI:
 ---------------------------------------------------------------------------------------------
 #    SURUCU MODEL / ETIKET           TUR                FS         TOPLAM   BOS ALAN  DURUM
 ---------------------------------------------------------------------------------------------
 [1]  C:     CT1000P3PSSD8            NVMe SSD (Dahili)  NTFS    930.26 GB  191.81 GB  [SISTEM DISKI]
 [2]  E:     YEDEK (Kingston DT 3.0)  USB Flash / Harici FAT32    29.80 GB   14.20 GB  [SALT OKUNUR / KILITLI]
 ---------------------------------------------------------------------------------------------

 SECENEKLER:
  [1-2] Bir disk secin ve kurtarma/onarim islemlerine baslayin
  [R]   Diskleri yeniden tara (Yeni bir flash bellek taktiysaniz)
  [P]   Bu araci 'recover' komutu olarak PowerShell'e kalici yukle
  [L]   Dili Degistir / Change Language (Aktif: Turkce)
  [Q]   Cikis
```

---

## Komut Parametreleri

| Parametre | Açıklama |
|---|---|
| `recover` | Etkileşimli ana menüyü başlatır. |
| `recover -List` | Takılı diskleri ve durumlarını tablo formatında listeler ve sonlanır. |
| `recover -Install` | Aracı geçerli PowerShell profil dosyasına kalıcı olarak kaydeder. |
| `recover -Uninstall` | Profil kaydını ve yerel çalışma dosyalarını sistemden temizler. |
| `recover -Lang <en\|tr>` | Arayüz dilini belirler (`en`: İngilizce, `tr`: Türkçe). |
| `recover -Help` | Parametre ve kullanım yardımını görüntüler. |

---

## Yazma Koruması Tanılama Modeli

Flash belleklerde salt okunur durum iki temel kaynaktan kaynaklanır:

| Kilit Türü | Mekanizma | Çözüm Yaklaşımı |
|---|---|---|
| **Yazılımsal Kilit** | Diskpart öznitelikleri, Windows Kayıt Defteri kısıtlamaları, dosya izinleri veya güvensiz çıkarma sonucu oluşan dosya sistemi `dirty bit` bayrağı. | PS-Recover tüm mantıksal katmanlardaki kilitleri temizler, Kayıt Defteri anahtarlarını sıfırlar ve birimi yeniden yazılabilir hale getirir. |
| **Donanımsal Koruma (NAND Wear-Out)** | Bellek kontrolcüsü, aşınmış bellek blokları veya kritik bad-sector artışı tespit ettiğinde veri kaybını önlemek için kalıcı salt okunur (Hardware ROM) moduna geçer. | Donanımsal kilit geri döndürülemez. PS-Recover **önce tüm verileri masaüstüne kurtarır**, ardından donanımsal arızayı raporlayarak veri kaybı riskini ortadan kaldırır. |

---

## Test ve Doğrulama

Sanal depolama ortamında birim ve entegrasyon testlerini çalıştırmak için:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test-recovery.ps1
```

---

## Sistemden Kaldırma

PS-Recover'ı sisteminizden tamamen kaldırmak için:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/ps-recovery/main/uninstall.ps1 | iex
```

Veya mevcut bir kurulum üzerinden:

```powershell
recover -Uninstall
```

---

## Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynak olarak yayımlanmıştır.
