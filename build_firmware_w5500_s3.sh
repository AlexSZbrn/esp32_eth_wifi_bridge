#!/bin/bash

# Собирает прошивку ESP32-S3 + W5500 (Waveshare ESP32-S3-ETH) и складывает бинари в firmware_w5500_s3/
#
# Использование:
#   . $IDF_PATH/export.sh
#   ./build_firmware_w5500_s3.sh

set -e

BUILD_DIR="build_w5500_s3"
OUT_DIR="firmware_w5500_s3"
BIN_NAME="esp32_eth_wifi_bridge"
SDKCONFIG="sdkconfig.w5500_s3"
SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.w5500_s3"

echo "=== W5500 + ESP32-S3 bridge firmware build (Waveshare ESP32-S3-ETH) ==="

if [ -z "$IDF_PATH" ]; then
    echo "ERROR: IDF_PATH не установлен. Сначала:"
    echo "  . \$IDF_PATH/export.sh"
    exit 1
fi

echo "IDF_PATH:   $IDF_PATH"
echo "Build dir:  $BUILD_DIR"
echo "Output dir: $OUT_DIR"
echo ""

echo "--- Очищаем предыдущий билд ---"
rm -rf "$BUILD_DIR"

# Удаляем stale sdkconfig чтобы он пересоздался из SDKCONFIG_DEFAULTS.
# Кешированный sdkconfig без CONFIG_ETH_UPLINK_W5500 тихо дефолтнется на EMAC.
rm -f "$SDKCONFIG"

echo "--- Билдим ---"
idf.py \
    -B "$BUILD_DIR" \
    -D SDKCONFIG="$SDKCONFIG" \
    -D SDKCONFIG_DEFAULTS="$SDKCONFIG_DEFAULTS" \
    set-target esp32s3

idf.py \
    -B "$BUILD_DIR" \
    -D SDKCONFIG="$SDKCONFIG" \
    -D SDKCONFIG_DEFAULTS="$SDKCONFIG_DEFAULTS" \
    build

echo ""
echo "--- Копируем бинари ---"
mkdir -p "$OUT_DIR"
cp "$BUILD_DIR/bootloader/bootloader.bin"           "$OUT_DIR/bootloader.bin"
cp "$BUILD_DIR/partition_table/partition-table.bin" "$OUT_DIR/partition-table.bin"
cp "$BUILD_DIR/ota_data_initial.bin"                "$OUT_DIR/ota_data_initial.bin"
cp "$BUILD_DIR/${BIN_NAME}.bin"                     "$OUT_DIR/${BIN_NAME}.bin"

echo ""
echo "=== Готово ==="
echo ""
echo "Файлы в $OUT_DIR/:"
ls -lh "$OUT_DIR/"
echo ""
echo "Команда прошивки (USB-C / ttyACM0):"
echo "  esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 460800 write_flash \\"
echo "    0x0000 $OUT_DIR/bootloader.bin \\"
echo "    0x8000 $OUT_DIR/partition-table.bin \\"
echo "    0xf000 $OUT_DIR/ota_data_initial.bin \\"
echo "    0x20000 $OUT_DIR/${BIN_NAME}.bin"
echo ""
echo "Первый запуск — подключись по serial 115200 и настрой AP:"
echo "  set_ap МойSSID МойПароль"
echo "  restart"
