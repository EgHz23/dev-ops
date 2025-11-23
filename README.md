Avtomatizirano razvojno okolje z Vagrantom, Ansible in VirtualBoxom

### Opis projekta

Ta projekt predstavlja popolnoma avtomatizirano razvojno in testno okolje za aplikacijo Report App.
Zgrajen je na osnovi tehnologij Vagrant, VirtualBox in Ansible, ki skupaj omogočajo enostavno ponovno ustvarjanje celotnega strežniškega okolja z enim samim ukazom:

"vagrant up"

Okolje samodejno nastavi:

operacijski sistem Ubuntu 22.04 (Jammy)
Nginx kot reverse proxy in strežnik statičnih datotek
PostgreSQL podatkovno bazo s samodejno ustvarjenimi uporabniki in pravicami
Python/FastAPI backend (z virtualnim okoljem)
Angular frontend
Redis strežnik
TLS certifikate (lokalni CA in podpisani strežniški certifikat)
UFW požarni zid
XFCE grafični vmesnik ter XRDP za oddaljen grafični dostop
systemd servis za zagon backend aplikacije

### Struktura projekta

dev-ops/
├── Vagrantfile
├── provision-base.sh
└── ansible/
    ├── inventory
    └── playbook.yml

### 1. Vagrantfile

Vagrantfile definira in vzpostavi navidezni stroj, na katerem teče celotna infrastruktura za Report App.

Ključne značilnosti

OS slika: ubuntu/jammy64

VirtualBox nastavitve:
4096 MB RAM
2 CPU jedri
vključen GUI (za XFCE)
DNS popravki (izogib težavam pri apt update)

Posredovanje portov:
HTTP: 8080 → 80
HTTPS: 8443 → 443
RDP: 33389 → 3389
Sinhronizirana mapa: lokalna mapa se preslika v /vagrant

Provisioning:
provision-base.sh namesti Ansible
ansible_local zažene glavni Ansible playbook

### 2. rovision-base.sh

Ta skripta pripravi osnovno okolje v navideznem stroju, da lahko Ansible pravilno deluje.

Funkcionalnost skripte:
posodobitev paketov (apt-get update)

namestitev:
Python 3
virtualenv
pip
git
orodja za upravljanje repozitorijev
Ansible

### 3. Ansible Playbook (ansible/playbook.yml)

Glavni del projekta predstavlja Ansible playbook, ki v celoti avtomatizira namestitev in konfiguracijo aplikacije Report App.

Playbook vsebuje več logičnih sklopov:

## 3.1 Sistemska priprava
nastavitev časovnega pasu
namestitev strežniških paketov:
Nginx
PostgreSQL in dodatki
Redis
build orodja
WeasyPrint odvisnosti (Cairo, Pango)

## 3.2 Uporabnik aplikacije

Ustvari se sistemski uporabnik reportapp, ki je namenjen izvajanju backend servisa.

## 3.3 Podatkovna baza

Samodejno se ustvari:
PostgreSQL baza reporting_db
uporabnik admin
geslo in privilegiji
nadzor nad ponovno izvedbo (idempotentnost)

## 3.4 Priprava aplikacije

Playbook:

ustvari /opt/reportapp
označi mapo kot varno za Git
klonira GitHub repozitorij aplikacije preko posredovanega osebnega dostopnega žetona
pripravi strukturo za loge in ustvarjene PDF/Word poročila

## 3.5 Backend (FastAPI)

ustvari virtualno okolje (venv)
namesti Python odvisnosti
ustvari /etc/reportapp.env s konfiguracijo aplikacije
ustvari systemd servis, ki samodejno zažene FastAPI backend

## 3.6 Frontend (Angular)

namesti Node.js iz uradnega NodeSource repozitorija
zažene npm install
zgradi Angular aplikacijo v production načinu

## 3.7 TLS certifikati

Samodejna generacija:

lokalnega CA (certifikacijskega organa)
strežniškega certifikata podpisanega z lokalnim CA
Namenjeno za razvojne HTTPS okolje, brez potrebe po zunanjih CA.

## 3.8 Nginx reverse proxy

Nginx je konfiguriran tako, da:
vsa HTTP promet preusmeri na HTTPS
/api/ usmerja na FastAPI backend (127.0.0.1:8000)
statične Angular datoteke streže iz build direktorija

## 3.9 Požarni zid

UFW omogoča le:

22/tcp – SSH
80/tcp – HTTP
443/tcp – HTTPS
3389/tcp – RDP

## 3.10 Grafični vmesnik + RDP

namestitev XFCE namiznega okolja
namestitev XRDP
omogočen oddaljen grafični dostop preko localhost:33389

Dostop:

Aplikacija (HTTP)
http://localhost:8080
Aplikacija (HTTPS)
https://localhost:8443

RDP
V RDP odjemalcu:
localhost:33389

"Vsa gesla v projektu so samo testna"

--------------------------------------------------------------------------

– Postavitev Aplikcaije ReportApp z uporabo Cloud-Init in Multipass

Opis

Ta del projekta predstavlja popolnoma avtomatiziran način namestitve Report App z uporabo cloud-init.

Cloud-init skripta:

namesti vse sistemske pakete (Nginx, PostgreSQL, Redis, Node.js, Python …),
ustvari TLS certifikate,
pripravi mape za backend in frontend aplikacijo,
klonira in namesti Report App,
vzpostavi systemd servis za FastAPI backend,
konfigurira Nginx kot reverse proxy,
omogoči UFW požarni zid,
nastavi XFCE grafično okolje (če je zaželeno),
zažene aplikacijo in zagotovi, da se ob vsakem zagonu samodejno zažene tudi backend.

Struktura: 

cloud-init/
└── cloud-init.yml

### 1. cloud-init.yml

Glavna konfiguracijska datoteka, ki jo Multipass uporabi:

### 1.1 Namestitev paketov

Cloud-init najprej izvede:
packages:
  - nginx
  - postgresql
  - postgresql-contrib
  - redis-server
  - git
  - python3
  - python3-pip
  - python3-venv
  - build-essential
  - python3-dev
  - libpq-dev
  - curl
  - gnupg
  - libpango-1.0-0
  - libpangoft2-1.0-0
  - libcairo2
  - libffi-dev
  - ufw
  - xfce4
  ...
Namestijo se ključni strežniški paketi

### 1.2 write_files

Vnaprej se ustvarijo ključne sistemske datoteke:

- reportapp.service (systemd servis)
Skrbi, da se FastAPI backend izvaja kot sistemska storitev:
teče kot uporabnik reportapp
uporablja virtualno okolje
samodejno restarta ob napaki

Nginx konfiguracija:

Datoteka /etc/nginx/sites-available/reportapp nastavi:
reverse proxy za /api/ → FastAPI backend
statično serviranje Angular frontenda
povečanje client_max_body_size
privzeto poslušanje na 80/tcp

Namestitveni skript install-reportapp.sh

To je osrednji del avtomatizacije.
Skripta vključuje:
ustvarjanje sistemskega uporabnika reportapp
namestitev PostgreSQL baze in uporabnika
kloniranje GitHub repozitorija
pripravljen Python virtualenv
namestitev Node.js (NodeSource)
build Angular frontenda
generiranje CA in TLS strežniškega certifikata
nastavitev okoljske datoteke /etc/reportapp.env
pripravo /app direktorijev za loge in poročila
konfiguracijo UFW
Cloud-init skrbi, da se skripta izvrši ob prvem zagonu.

### 1.3 runcmd

Na koncu se izvede:
runcmd:
  - [ bash, -c, "chmod +x /usr/local/bin/install-reportapp.sh && /usr/local/bin/install-reportapp.sh" ]

### 2. Uporaba z Multipass

Multipass omogoča enostavno ustvarjanje Ubuntu VM-jev s cloud-init skriptami.

Ustvarjanje virtualnega stroja:
multipass launch `
>>   --name reportapp `
>>   --disk 30G `
>>   --memory 8G `
>>   --cpus 4 `
>>   --cloud-init "C:\Users\egzon\dev-ops\cloud-init\cloud-init.yml" `
>>   --timeout 1800 `
>>   --network Wi-Fi

### 2.1 Dostop do VM-ja

SSH:
multipass shell reportapp

Pridobivanje IP naslova:
multipass info reportapp

### 3. Dostop do aplikacije

Ko cloud-init zaključi, je aplikacija dostopna na:
- HTTP:
http://<VM-IP>/
- API (FastAPI backend):
http://<VM-IP>/api/
- Nginx reverse proxy je prednastavljen za razvojne potrebe.
