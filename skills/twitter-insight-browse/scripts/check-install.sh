#!/usr/bin/env bash
# Check & install opencli + verify Browser Bridge for twitter-insight-browse skill.
# Usage: bash scripts/check-install.sh
# Exit codes:
#   0  all checks passed
#   1  hard failure (manual action required)
#   2  installed something, please re-run

set -e

echo "==> [1/4] Checking Node.js..."
if ! command -v node >/dev/null 2>&1; then
  cat <<'EOF'
❌ Node.js not installed.
   macOS:  brew install node
   其他:   https://nodejs.org/  (要求 >= 21.0.0)
EOF
  exit 1
fi

NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
if [ "$NODE_MAJOR" -lt 21 ]; then
  echo "❌ Node.js $(node -v) too old. opencli requires >= 21.0.0"
  echo "   macOS: brew upgrade node"
  exit 1
fi
echo "   ✅ Node.js $(node -v)"

echo "==> [2/4] Checking opencli..."
if ! command -v opencli >/dev/null 2>&1; then
  echo "   ⚠️  opencli not found, installing @jackwener/opencli globally..."
  if ! npm install -g @jackwener/opencli; then
    echo "❌ npm install failed."
    echo "   如果是权限错误，可以试: sudo npm install -g @jackwener/opencli"
    echo "   或配置 npm prefix: npm config set prefix ~/.npm-global"
    exit 1
  fi
  echo "   ✅ opencli installed: $(opencli --version 2>/dev/null || echo unknown)"
else
  echo "   ✅ opencli $(opencli --version 2>/dev/null || echo installed)"
fi

echo "==> [3/4] Checking twitter adapter..."
if ! opencli twitter -h >/dev/null 2>&1; then
  echo "❌ 'opencli twitter' adapter not available."
  echo "   尝试更新: npm install -g @jackwener/opencli@latest"
  exit 1
fi
echo "   ✅ twitter adapter available"

echo "==> [4/4] Checking Browser Bridge connectivity..."
DOCTOR_OUT=$(opencli doctor 2>&1 || true)
if echo "$DOCTOR_OUT" | grep -qiE "extension.*not.*connected|disconnect|not.*available|unhealthy"; then
  cat <<'EOF'
❌ Browser Bridge extension not connected.

Browser Bridge 扩展无法自动安装，请手动完成：
  1. 打开 https://github.com/jackwener/opencli/releases
  2. 下载最新的 opencli-extension-v{version}.zip 并解压
  3. Chrome 打开 chrome://extensions
  4. 启用右上角「开发者模式 / Developer mode」
  5. 点击「加载已解压的扩展程序 / Load unpacked」，选择解压后的目录
  6. 确认浏览器已登录 https://x.com

完成后重新运行: bash scripts/check-install.sh
EOF
  echo ""
  echo "--- opencli doctor output ---"
  echo "$DOCTOR_OUT"
  exit 1
fi
echo "   ✅ Browser Bridge connected"

echo ""
echo "✅ All checks passed. Ready to use 'opencli twitter ...' commands."
