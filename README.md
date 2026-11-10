# 🛡️ PS-Recover

**Windows Gelişmiş Disk, USB & Flash Bellek Kurtarma Aracı**  
*PowerShell üzerinde tek bir komutla (`recover`) veya tek satır `iex` ile doğrudan çalışan taşınabilir veri kurtarma ve onarım çözümü.*

---

## ⚡ Hızlı Başlangıç (Tek Satırda Çalıştırın)

Hiçbir kurulum yapmadan, Git veya harici bir program yüklemeden, **Windows PowerShell**'i açıp aşağıdaki tek satırı yapıştırmanız yeterlidir:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/drive-recovery/main/recover.ps1 | iex
```

### 📌 Kalıcı Olarak Sisteme Yüklemek İçin:
PowerShell'i her açtığınızda doğrudan `recover` yazarak araca ulaşmak istiyorsanız:

```powershell
irm https://raw.githubusercontent.com/AybarsBarut/drive-recovery/main/install.ps1 | iex
```

---

## 🚀 Öne Çıkan Özellikler

- **🔍 Otomatik Sürücü Tespiti ve Listeleme:**
  - Takılı olan tüm USB flash bellekleri, harici diskleri ve dahili SSD/HDD birimlerini model adı, etiket, kapasite, dosya sistemi ve doluluk oranlarıyla listeler.
  - Sürücünün **Salt Okunur (Yazma Korumalı)** olup olmadığını anında tespit eder ve renkli uyarıyla bildirir.

- **📂 Masaüstüne Güvenli Aktarım (`Desktop\recovered`):**
  - Seçilen diskteki dosyalar `Masaüstü\recovered\Kurtarma_<Harf>_<Tarih>` klasörüne hiyerarşik yapısı bozulmadan kopyalanır.
  - Birden fazla kurtarma oturumu yapıldığında dosyalarınız asla birbiriyle karışmaz veya üzerine yazılmaz.

- **🦠 Kısayol Virüsü (Shortcut Virus) ve Gizli Dosyaları Kurtarma:**
  - Flash belleklere bulaşan ve klasörleri gizleyip yerine `.lnk` kısayolları koyan virüslerin gizlediği gerçek verileri açığa çıkarır.
  - Kurtarılan dosyaların üzerindeki `Gizli (Hidden)`, `Sistem (System)` ve `Salt Okunur (ReadOnly)` özniteliklerini otomatik temizleyerek dosyaları hemen açılabilir hale getirir.

- **🎯 Dosya Türüne Göre Seçici Kurtarma:**
  - İsteğe bağlı olarak sadece Belgeler (Word, Excel, PDF), Fotoğraflar (JPG, PNG, RAW), Videolar (MP4, MKV), Sesler, Arşivler (ZIP, RAR) veya özel uzantılar kurtarılabilir.

- **🛠️ Salt Okunur / Yazma Korumalı Flash Bellekleri Düzeltme:**
  - **1. Güvenlik Yedeği:** Bellek kontrolcüsünü riske atmamak için onarımdan önce tüm verileri masaüstüne otomatik yedekler.
  - **2. Diskpart Kilidi Temizleme:** Disk ve birim düzeyindeki `readonly` bayraklarını temizler.
  - **3. Storage API Onarımı:** Windows çekirdek depolama katmanındaki salt okunur durumunu kaldırır.
  - **4. Windows Kayıt Defteri (Registry):** `StorageDevicePolicies` altındaki `WriteProtect` kilidini sıfırlar.
  - **5. Dosya İzinleri & Attrib:** Tüm dosya sistemindeki öznitelikleri (`attrib -r -s -h`) açar.
  - **6. Dosya Sistemi Onarımı:** Chkdsk ile dosya sistemindeki `dirty bit` ve bozuk sektör indekslerini onarır.
  - **7. Donanımsal Teşhis Testi:** Bellek hücrelerinin ömrünü doldurmasından (NAND exhaustion) kaynaklanan donanımsal kilit ile yazılımsal kilidi ayırt eder ve kullanıcıya net teknik teşhis sunar.

- **📊 Detaylı Raporlama:**
  - İşlem bittiğinde taranan, başarıyla kurtarılan ve hatalı dosya sayıları ile aktarılan boyut konsolda özetlenir.
  - Kurtarılan tüm dosyaların dökümünü içeren UTF-8 formatlı `kurtarma_raporu.txt` dosyası otomatik oluşturulur.
  - Kullanıcıya tek tuşla masaüstündeki kurtarma klasörünü dosya gezgininde açma imkanı sunar.

---

## 🖥️ Arayüz Önizlemesi

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

## 📖 Kullanım Rehberi

### 1. Doğrudan Çalıştırma
PowerShell terminalinde:
```powershell
recover
```
yazarak interaktif menüyü başlatabilirsiniz.

### 2. Parametreli Hızlı Kullanım
- **Sadece diskleri listele:**
  ```powershell
  recover -List
  ```
- **Kalıcı kurulum:**
  ```powershell
  recover -Install
  ```
- **Sistemden kaldırma:**
  ```powershell
  recover -Uninstall
  ```

---

## ❓ Salt Okunur Flash Bellekler Neden Kilitlenir?

Flash bellekler iki farklı mekanizmayla salt okunur duruma düşebilir:

| Kilit Türü | Neden Oluşur? | PS-Recover Çözümü |
|---|---|---|
| **Yazılımsal Kilit** | Diskpart öznitelikleri, Windows Kayıt Defteri kısıtlaması, virüsler veya güvenli kaldırılmadan çekilmesi sonucu dosya sisteminin bozulması (`dirty bit`). | PS-Recover tüm kilitleri otomatik temizler ve belleği tekrar yazılabilir hale getirir. |
| **Donanımsal Koruma (NAND Wear-Out)** | Bellek yongalarındaki hücreler yazma ömrünü tükettiğinde veya fiziksel arıza oluştuğunda kontrolcü verilerin kaybolmaması için kalıcı okuma moduna (ROM) geçer. | PS-Recover **önce tüm verilerinizi masaüstüne eksiksiz kurtarır**, ardından kontrolcüye yazma testi yaparak donanımsal arızayı kesinleştirir ve sizi bilgilendirir. |

---

## 🧪 Testler

Bu proje otomatik testlerle doğrulanmıştır. Testleri yerel olarak çalıştırmak için:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test-recovery.ps1
```

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynak olarak dağıtılmaktadır.
