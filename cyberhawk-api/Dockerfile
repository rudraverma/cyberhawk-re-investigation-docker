FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKSPACE=/workspace
# Playwright: tell it where to store browsers and use headless Chromium
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0

# ── System analysis tools (all verified in Debian trixie) ─────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Network
    dnsutils whois curl wget netcat-openbsd nmap tcpdump tshark \
    # File identification & carving
    file binutils exiftool binwalk foremost scalpel \
    # Malware utilities
    ssdeep upx-ucl strace ltrace \
    # Archive extraction
    p7zip-full unzip \
    # Disk forensics
    sleuthkit \
    # AV
    clamav clamav-freshclam \
    # Build & system
    git procps build-essential libmagic1 \
    # ── Headless Chromium / Playwright system dependencies ──────────────────
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libdrm2 libdbus-1-3 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libgbm1 libasound2 libpango-1.0-0 \
    libpangocairo-1.0-0 libcairo2 libx11-6 libx11-xcb1 libxcb1 \
    libxext6 libxshmfence1 libglib2.0-0 fonts-liberation \
    xvfb xauth \
    && rm -rf /var/lib/apt/lists/*

# ── Radare2 — installed from official GitHub release (not in Debian trixie apt)
RUN curl -Ls https://github.com/radareorg/radare2/releases/download/5.9.4/radare2_5.9.4_amd64.deb \
    -o /tmp/r2.deb \
    && dpkg -i /tmp/r2.deb \
    && rm /tmp/r2.deb

# ── Python dependencies ────────────────────────────────────────────────────────
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# ── Playwright: install Chromium browser into image ───────────────────────────
RUN playwright install chromium \
    && playwright install-deps chromium

# ── App source ─────────────────────────────────────────────────────────────────
COPY app/ ./app/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
