#!/usr/bin/env bash
# Regenerate the embedded icon data for index.html's ICON_IMG table.
# Fetches real WoW icon art from the Wowhead CDN (zamimg) and prints a
# ready-to-paste JS object of base64 data URIs. ~1.8KB per icon.
set -euo pipefail

# key=zamimg slug (large = 56x56 JPEG)
ICONS=(
  "coldSnap=spell_frost_wizardmark"
  "berserking=racial_troll_berserk"
  "icyVeins=spell_frost_coldhearted"
  "isc=inv_weapon_shortblade_23"
  "scb=spell_nature_poisoncleansingtotem"
  "arcanePower=spell_nature_lightning"
  "bloodlust=spell_nature_bloodlust"
  "drums=inv_misc_drum_02"
  "powerInfusion=spell_holy_powerinfusion"
  "skull=inv_misc_bone_elfskull_01"
  "ati=inv_misc_elvencoins"
  "mqg=spell_nature_wispheal"
  "manaEmerald=inv_misc_gem_stone_01"
)

echo "const ICON_IMG = {"
for pair in "${ICONS[@]}"; do
  key="${pair%%=*}"; slug="${pair#*=}"
  b64=$(curl -sf "https://wow.zamimg.com/images/wow/icons/large/${slug}.jpg" | base64 | tr -d '\n')
  echo "  ${key}: \"data:image/jpeg;base64,${b64}\","
done
echo "};"
