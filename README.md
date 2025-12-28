# Avtomatizirano razvojno in testno okolje za Report App

Ta repozitorij vsebuje **tri različne avtomatizirane rešitve** za postavitev aplikacije **Report App**:

1. **Vagrant + Ansible + VirtualBox** – lokalno razvojno okolje
2. **Cloud-init + Multipass** – hitra postavitev VM-ja
3. **Docker + Ansible (Infra as Code)** – kontejnerska različica z Docker Compose in GHCR

Cilj projekta je omogočiti **ponovljivo, enostavno in zanesljivo** postavitev celotnega okolja (backend, frontend, baza, reverse proxy, varnost) z enim samim ukazom.

> **Vsa gesla in certifikati v projektu so namenjeni izključno razvoju in testiranju.**

---

## Namen projekta

Namen projekta je prikazati **celovito avtomatizacijo postavitve sodobnega aplikacijskega stacka** z uporabo orodij in praks, ki se uporabljajo v realnih DevOps okoljih. Projekt združuje virtualizacijo, konfiguracijski management, kontejnerizacijo, CI/CD in varnost ter omogoča hitro, ponovljivo in zanesljivo postavitev razvojnega ali demo okolja.

Projekt je razvit kot del študijskih vaj in služi kot:

- demonstracija znanja iz **virtualizacije in avtomatizacije**,
- osnova za **lokalni razvoj ali predstavitev aplikacije**,
- primer dobre prakse za **Infrastructure as Code (IaC)**.

---

## Tehnološki pregled

Projekt uporablja naslednje tehnologije:

- **Ubuntu 22.04 (Jammy)**
- **FastAPI (Python backend)**
- **Angular (frontend)**
- **PostgreSQL**
- **Redis**
- **Nginx** (reverse proxy)
- **Docker + Docker Compose** (za kontejnersko različico)
- **TLS certifikati (lokalni/self-signed ali Let's Encrypt)**
- **systemd** za avtomatski zagon backend servisa
- **UFW požarni zid**
- **XFCE + XRDP** (grafični dostop preko RDP)
- **CI/CD** z GitHub Actions za avtomatsko buildanje image-ov
- **Buildx / multi-stage Docker build** za optimizacijo image-ov

---

# Možnost A: Vagrant + Ansible + VirtualBox

Ta možnost je namenjena predvsem **lokalnemu razvoju** in omogoča popolnoma avtomatizirano postavitev z ukazom:

```bash
vagrant up
```

## Zahteve

- VirtualBox
- Vagrant

## Zagon
```bash
cd dev-ops
vagrant up
```
Ob prvem zagonu se:
- ustvari VM
- namesti Ansible
- izvede Ansible playbook
- zažene celotna aplikacija

### Struktura projekta
```
dev-ops/
├── Vagrantfile
├── provision-base.sh
└── ansible/
    ├── inventory
    └── playbook.yml
```

### Kaj se samodejno nastavi

#### Sistem

- Ubuntu 22.04
- Časovni pas
- UFW požarni zid

#### Storitve

- Nginx (reverse proxy + static)
- PostgreSQL (baza + uporabnik)
- Redis
- systemd servis za FastAPI

#### Backend

- Python virtualno okolje
- FastAPI aplikacija
- `/etc/reportapp.env` konfiguracija

#### Frontend

- Node.js (NodeSource)
- `npm install`
- Angular production build

#### TLS

- Lokalni self-signed CA in certifikat

#### Grafični dostop

- XFCE
- XRDP

### Dostop

#### Aplikacija

- HTTP: http://localhost:8080
- HTTPS: https://localhost:8443

#### API

- https://localhost:8443/api/

#### RDP
- localhost:33389

# Možnost B: Cloud-init + Multipass

Omogoča **hitro postavitev VM-ja** z uporabo `cloud-init` brez Ansible-a.

### Struktura

```
cloud-init/
└── cloud-init.yml
```

### Kaj naredi cloud-init

- Namesti vse sistemske pakete
- Ustvari uporabnika `reportapp`
- Nastavi PostgreSQL bazo
- Klonira Report App repozitorij
- Pripravi Python virtualenv
- Zgradi Angular frontend
- Ustvari TLS certifikate
- Konfigurira Nginx
- Nastavi UFW
- Ustvari systemd servis
- Po želji namesti XFCE
- Po zagonu VM-ja zažene aplikacijo

### Zagon z Multipass

```bash
multipass launch \
  --name reportapp \
  --disk 30G \
  --memory 8G \
  --cpus 4 \
  --cloud-init "cloud-init/cloud-init.yml" \
  --timeout 1800
```

### Dostop

#### SSH

```bash
multipass shell reportapp
multipass info reportapp
```

### Aplikacija

- http://<VM-IP>/
- http://<VM-IP>/api/

# Možnost C: Docker + Ansible

Ta možnost uvaja **kontejnersko arhitekturo** za Report App in je namenjena produkcijsko podobnemu okolju. Celoten stack (frontend, backend, scheduler, PostgreSQL, Nginx, Certbot) teče v Docker kontejnerjih, orkestriranih z **Docker Compose**.

Namestitev in zagon sta avtomatizirana z **Ansible playbookom**, ki pripravi infrastrukturo, direktorije, TLS ter zažene celoten stack.

---

## Struktura (Docker / Infra)

```text
vagrant/
├── ansible/
│   └── playbook-docker.yml
└── infra/
    ├── docker-compose.yml
    ├── .env
    ├── conf.d/
    │   ├── default.conf
    │   └── timeout.conf
    ├── audit-logs/
    ├── generated-reports/
    ├── ssl/
    └── certbot/
        ├── conf/
        └── www/
```

playbook-docker.yml

Ansible playbook, ki:

- namesti Docker Engine, Docker Compose plugin in Buildx
- klonira report-app / dev-ops repozitorij na VM (/opt/reportapp)

preveri prisotnost:
    - docker-compose.yml
    - Nginx konfiguracije (conf.d)
    - .env datoteke

pripravi direktorije za: audit loge, generirana poročila

TLS certifikate (ssl/)

- Certbot podatke (certbot/conf, certbot/www)
- (po potrebi) generira self-signed TLS certifikat
- prijavi VM v GitHub Container Registry (GHCR)

izvede:
docker compose pull
docker compose up -d


Playbook je **idempotenten** in varen za večkratni zagon.

---

## docker-compose.yml

Definira celoten aplikacijski stack.

### Storitevni pregled

- **postgres**
- PostgreSQL 16 (Alpine)
- persistent volume (`pgdata`)
- healthcheck (`pg_isready`)
- **backend**
- FastAPI aplikacija
- REST API (`/api`)
- Gunicorn konfiguracija (workers, threads, timeout)
- **scheduler**
- ločen kontejner kot backend
- zaganja asinhroni scheduler (`RUN_SCHEDULER=1`)
- **frontend**
- Angular aplikacija 
- **nginx**
- reverse proxy
- HTTPS terminacija
- routing frontend / backend
- **certbot**
- pridobivanje in obnavljanje Let’s Encrypt certifikatov

---

### Posebnosti konfiguracije

- uporaba **`.env` datoteke** za občutljive nastavitve:
- JWT nastavitve
- lokalna avtentikacija
- CORS
- Fernet ključ
- skupno Docker omrežje: avichron-ent

- shared volume-i za:
- audit loge
- generirana poročila
- PostgreSQL povezava prek DNS imena `postgres`

### Nginx konfiguracija (Docker)

#### default.conf

- HTTP → HTTPS preusmeritev
- `/api/` → FastAPI backend (`backend:8000`)
- `/` → Angular frontend
- SPA fallback za Angular deep-linke
- podpora za večje zahteve (`client_max_body_size 50m`)

#### timeout.conf

Poveča proxy timeout vrednosti (primerno za dolgotrajne reporte):

- `proxy_connect_timeout 600`
- `proxy_read_timeout 600`
- `proxy_send_timeout 600`


---

## TLS / HTTPS

Podprti sta **dve možnosti TLS**:

### 1. Self-signed TLS (privzeto za razvoj)

- generiran z Ansible playbookom
- certifikati mountani v Nginx (`/etc/ssl`)
- namenjeno razvoju in testiranju

### 2. Let’s Encrypt (Certbot)

- uporabljen `certbot` Docker image
- certifikati shranjeni v:
    certbot/conf, webroot:


### Zagon (Docker varianta)

Po zagonu VM-ja:

```bash
ansible-playbook vagrant/ansible/playbook-docker.yml
```

Aplikacija je nato dostopna na:

- https://localhost/
- https://localhost/api/

## CI/CD pipeline (GitHub Actions)

Več o tem na:  
https://github.com/EgHz23/report-app/blob/main/README.md

Docker image-i za **backend** in **frontend** se **samodejno gradijo in objavljajo** v **GitHub Container Registry (GHCR)**.

Pipeline vključuje:

- multi-stage Docker build
- Docker Buildx
- taganje (`latest`, commit SHA)
- push v `ghcr.io/eghz23/...`

## Dokazila

- **Zaslonski posnetki**:
  - Docker ps:

    <img width="1793" height="129" alt="image" src="https://github.com/user-attachments/assets/24a38473-0cfd-4a87-8577-ce19abee5567" />


  - delujoča aplikacija v brskalniku (HTTP/HTTPS):
  
    <img width="1579" height="409" alt="image" src="https://github.com/user-attachments/assets/a660fa61-56ce-41bf-881f-ecc7a64fd889" />


  - Paketi:

    <img width="558" height="248" alt="image" src="https://github.com/user-attachments/assets/44c2502d-150b-4321-b385-89ace1dd0e49" />

## Javni dostop (deployment)

Aplikacija je dostopna na:  https://avichron.com/
