timestamp() {
  echo "$(date +%s)"
}

wait() {
  local readonly file="${1}"
  local readonly max="${2:-5}"
  local readonly start="$(timestamp)"

  while [[ ! -f "${file}" ]]; do
    [[ $(($(timestamp)-${start})) -gt ${max} ]] \
      && break
  done
}

readonly webroot="/var/www/lisp"
readonly nginx="/etc/nginx"
readonly quicklisp_root="~/quicklisp";
readonly socket_c="/var/run/fcgi-c.socket"
readonly socket_lisp="/var/run/fcgi-lisp.socket"

echo "Installing packages..."
apt-get -y update \
  >/dev/null 2>&1
apt-get -y install \
  vim \
  curl \
  nginx \
  gcc \
  make \
  libfcgi-dev \
  spawn-fcgi \
  sbcl \
  >/dev/null 2>&1

echo "Creating sources..."
if [[ ! -d "${webroot}" ]]; then
  mkdir -p "${webroot}";
fi

if [[ ! -d "${webroot}/public" ]]; then
  cp -r "/vagrant/public" "${webroot}"
  chown -R www-data:www-data "${webroot}/public"
fi

if [[ ! -d "${webroot}/app" ]]; then
  cp -r "/vagrant/app" "${webroot}"
fi

if [[ ! -f "${nginx}/sites-enabled/lisp" ]]; then
  echo "Configuring nginx..."
  cp "/vagrant/lisp.conf" "${nginx}/sites-available/lisp"
  ln -s "${nginx}/sites-available/lisp" "${nginx}/sites-enabled"
else
  echo "nginx already configured"
fi

if [[ ! -d "${quicklisp_root}" ]]; then
  echo "Installing quicklisp and cl-fastcgi..."
  (
    cd /tmp
    curl -O "https://beta.quicklisp.org/quicklisp.lisp" \
      >/dev/null 2>&1
    sbcl \
      --load "quicklisp.lisp" \
      --eval "(quicklisp-quickstart:install :path \"${quicklisp_root}/\")" \
      --eval "(ql:system-apropos \"cl-fastcgi\")" \
      --eval "(quit)" \
      >/dev/null 2>&1
    rm "quicklisp.lisp"
  )
else
  echo "quicklisp and cl-fastcgi already installed"
fi

if [[ -z "$(which buildapp)" ]]; then
  echo "Installing buildapp..."
  (
    cd "/tmp"
    wget "http://www.xach.com/lisp/buildapp.tgz" \
      >/dev/null 2>&1
    mkdir "buildapp"
    tar -xzf "buildapp.tgz" --strip 1 -C "buildapp"
    cd "buildapp"
    make install \
      >/dev/null 2>&1
    rm -rf "buildapp.tgz" "buildapp"
  )
else
  echo "buildapp already installed"
fi

echo "Building application servers..."
(
  cd "${webroot}/app"
  make clean >/dev/null 2>&1
  make >/dev/null 2>&1
)

echo "Launching application servers..."
spawn-fcgi -s "${socket_c}" -n "${webroot}/app/main-c" >/dev/null &
wait "${socket_c}"
chmod 777 "${socket_c}"

spawn-fcgi -s "${socket_lisp}" -n "${webroot}/app/main-lisp" >/dev/null &
wait "${socket_lisp}"
chmod 777 "${socket_lisp}"

echo "Restarting web server"
service nginx restart >/dev/null 2>&1
