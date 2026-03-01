#!/usr/bin/env python3
"""App Store Connect API — アプリ自動登録スクリプト

テンプレート JSON を元に、Bundle ID 登録からスクリーンショットアップロードまで
全自動で App Store Connect に登録する。

Usage:
    python3 store/register_app.py store/apps/fukushi2.json
    python3 store/register_app.py store/apps/fukushi2.json --dry-run
"""

import jwt
import time
import requests
import json
import sys
import os
import hashlib
import mimetypes

# === 設定 ===
KEY_ID = "7P39336774"
ISSUER_ID = "35a2f02c-136f-4b1b-aadb-c196cc50a08a"
KEY_FILE = "/Users/shinichikinuwaki/Desktop/private_key.p8"

BASE_URL = "https://api.appstoreconnect.apple.com"

# スクリーンショット表示タイプ
SCREENSHOT_DISPLAY_TYPES = {
    "iphone": "APP_IPHONE_67",
    "ipad": "APP_IPAD_PRO_6GEN_129",
}

DRY_RUN = False


# ─────────────────────────────────────────────
# JWT トークン生成
# ─────────────────────────────────────────────
def generate_token():
    with open(KEY_FILE, "r") as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


# ─────────────────────────────────────────────
# API ヘルパー
# ─────────────────────────────────────────────
_token = None
_token_created = 0


def get_token():
    global _token, _token_created
    now = time.time()
    if _token is None or now - _token_created > 1000:
        _token = generate_token()
        _token_created = now
    return _token


def headers():
    return {
        "Authorization": f"Bearer {get_token()}",
        "Content-Type": "application/json",
    }


def api_get(path, params=None):
    url = f"{BASE_URL}{path}"
    if DRY_RUN:
        print(f"  [DRY-RUN] GET {url} params={params}")
        return None
    resp = requests.get(url, headers=headers(), params=params or {})
    if resp.status_code == 200:
        return resp.json()
    if resp.status_code == 404:
        return None
    print(f"  [ERROR] GET {path} -> {resp.status_code}: {resp.text[:300]}")
    return None


def api_post(path, payload):
    url = f"{BASE_URL}{path}"
    if DRY_RUN:
        print(f"  [DRY-RUN] POST {url}")
        print(f"    payload: {json.dumps(payload, ensure_ascii=False)[:500]}")
        return {"data": {"id": "dry-run-id", "attributes": {}}}
    resp = requests.post(url, headers=headers(), json=payload)
    if resp.status_code in (200, 201):
        return resp.json()
    print(f"  [ERROR] POST {path} -> {resp.status_code}: {resp.text[:500]}")
    return None


def api_patch(path, payload):
    url = f"{BASE_URL}{path}"
    if DRY_RUN:
        print(f"  [DRY-RUN] PATCH {url}")
        print(f"    payload: {json.dumps(payload, ensure_ascii=False)[:500]}")
        return {"data": {"id": "dry-run-id", "attributes": {}}}
    resp = requests.patch(url, headers=headers(), json=payload)
    if resp.status_code == 200:
        return resp.json()
    print(f"  [ERROR] PATCH {path} -> {resp.status_code}: {resp.text[:500]}")
    return None


def api_put_binary(url, data, content_type):
    """バイナリアップロード用"""
    if DRY_RUN:
        print(f"  [DRY-RUN] PUT {url} ({len(data)} bytes)")
        return True
    h = {"Content-Type": content_type}
    resp = requests.put(url, headers=h, data=data)
    if resp.status_code in (200, 201):
        return True
    print(f"  [ERROR] PUT -> {resp.status_code}: {resp.text[:300]}")
    return False


# ─────────────────────────────────────────────
# Step 1: Bundle ID 登録
# ─────────────────────────────────────────────
def register_bundle_id(config):
    print("\n=== Step 1: Bundle ID 登録 ===")
    bundle_id = config["app"]["bundleId"]

    # 既存チェック
    existing = api_get("/v1/bundleIds", {"filter[identifier]": bundle_id})
    if existing and existing.get("data"):
        bid = existing["data"][0]["id"]
        print(f"  既存の Bundle ID を使用: {bid}")
        return bid

    payload = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": bundle_id,
                "name": config["app"]["sku"],
                "platform": "IOS",
            },
        }
    }
    result = api_post("/v1/bundleIds", payload)
    if result:
        bid = result["data"]["id"]
        print(f"  Bundle ID 登録完了: {bid}")
        return bid
    print("  [FAIL] Bundle ID 登録失敗")
    return None


# ─────────────────────────────────────────────
# Step 2: アプリ作成
# ─────────────────────────────────────────────
def create_app(config, bundle_id_resource_id):
    print("\n=== Step 2: アプリ作成 ===")
    bundle_id = config["app"]["bundleId"]

    # 既存チェック
    existing = api_get("/v1/apps", {"filter[bundleId]": bundle_id})
    if existing and existing.get("data"):
        app_id = existing["data"][0]["id"]
        print(f"  既存のアプリを使用: {app_id}")
        return app_id

    payload = {
        "data": {
            "type": "apps",
            "attributes": {
                "name": config["app"]["name"],
                "primaryLocale": config["app"].get("primaryLocale", "ja"),
                "sku": config["app"]["sku"],
                "bundleId": bundle_id,
                "contentRightsDeclaration": config["app"].get(
                    "contentRightsDeclaration", "DOES_NOT_USE_THIRD_PARTY_CONTENT"
                ),
            },
            "relationships": {
                "bundleId": {
                    "data": {
                        "type": "bundleIds",
                        "id": bundle_id_resource_id,
                    }
                }
            },
        }
    }
    result = api_post("/v1/apps", payload)
    if result:
        app_id = result["data"]["id"]
        print(f"  アプリ作成完了: {app_id}")
        return app_id

    # FORBIDDEN の場合は手動案内
    print("\n  ⚠ アプリ作成が API から拒否されました。")
    print("  App Store Connect Web で手動作成してください。")
    print("  https://appstoreconnect.apple.com/apps")
    print("  作成後、--app-id <APP_ID> オプションを付けて再実行してください。")
    if DRY_RUN:
        return "dry-run-app-id"
    return None


# ─────────────────────────────────────────────
# Step 3: App Info 取得 → カテゴリ設定
# ─────────────────────────────────────────────
def setup_app_info(config, app_id):
    print("\n=== Step 3: App Info (カテゴリ設定) ===")

    # App Info 取得
    app_data = api_get(f"/v1/apps/{app_id}/appInfos")
    if not app_data or not app_data.get("data"):
        print("  [FAIL] App Info 取得失敗")
        return None

    app_info_id = app_data["data"][0]["id"]
    print(f"  App Info ID: {app_info_id}")

    # カテゴリ設定
    category = config.get("appInfo", {}).get("primaryCategory", "EDUCATION")
    payload = {
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {
                "primaryCategory": {
                    "data": {
                        "type": "appCategories",
                        "id": category,
                    }
                }
            },
        }
    }
    result = api_patch(f"/v1/appInfos/{app_info_id}", payload)
    if result:
        print(f"  カテゴリ設定完了: {category}")
    else:
        print(f"  [WARN] カテゴリ設定失敗（続行）")

    return app_info_id


# ─────────────────────────────────────────────
# Step 4: App Info Localization 更新
# ─────────────────────────────────────────────
def setup_app_info_localizations(config, app_info_id):
    print("\n=== Step 4: App Info Localization ===")

    # 既存 localization 取得
    existing = api_get(f"/v1/appInfos/{app_info_id}/appInfoLocalizations")
    existing_map = {}
    if existing and existing.get("data"):
        for loc in existing["data"]:
            existing_map[loc["attributes"]["locale"]] = loc["id"]

    for loc_config in config.get("appInfoLocalizations", []):
        locale = loc_config["locale"]
        attrs = {}
        for key in ["name", "subtitle", "privacyPolicyUrl", "privacyChoicesUrl", "privacyPolicyText"]:
            if key in loc_config and loc_config[key] is not None:
                attrs[key] = loc_config[key]

        if locale in existing_map:
            # 更新
            loc_id = existing_map[locale]
            payload = {
                "data": {
                    "type": "appInfoLocalizations",
                    "id": loc_id,
                    "attributes": attrs,
                }
            }
            result = api_patch(f"/v1/appInfoLocalizations/{loc_id}", payload)
            if result:
                print(f"  [{locale}] 更新完了")
            else:
                print(f"  [{locale}] [WARN] 更新失敗（続行）")
        else:
            # 新規作成
            payload = {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": {**attrs, "locale": locale},
                    "relationships": {
                        "appInfo": {
                            "data": {"type": "appInfos", "id": app_info_id}
                        }
                    },
                }
            }
            result = api_post("/v1/appInfoLocalizations", payload)
            if result:
                print(f"  [{locale}] 作成完了")
            else:
                print(f"  [{locale}] [WARN] 作成失敗（続行）")


# ─────────────────────────────────────────────
# Step 5: App Store Version 作成
# ─────────────────────────────────────────────
def create_version(config, app_id):
    print("\n=== Step 5: App Store Version 作成 ===")
    version_string = config["version"]["versionString"]

    # 既存バージョンチェック（編集可能なもの）
    existing = api_get(f"/v1/apps/{app_id}/appStoreVersions", {
        "filter[appStoreState]": "PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED,WAITING_FOR_REVIEW,IN_REVIEW",
        "fields[appStoreVersions]": "versionString,appStoreState",
    })
    if existing and existing.get("data"):
        ver = existing["data"][0]
        ver_id = ver["id"]
        state = ver["attributes"]["appStoreState"]
        print(f"  既存バージョン使用: {ver_id} (v{ver['attributes']['versionString']}, {state})")
        # PREPARE_FOR_SUBMISSION で過去にリリース済みバージョンがなければ初回
        is_first = (state == "PREPARE_FOR_SUBMISSION")
        return ver_id, is_first

    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {
                "versionString": version_string,
                "copyright": config["version"].get("copyright", "2026 ktwvai Inc."),
                "releaseType": config["version"].get("releaseType", "AFTER_APPROVAL"),
                "reviewType": config["version"].get("reviewType", "APP_STORE"),
            },
            "relationships": {
                "app": {
                    "data": {"type": "apps", "id": app_id}
                }
            },
        }
    }
    result = api_post("/v1/appStoreVersions", payload)
    if result:
        ver_id = result["data"]["id"]
        print(f"  バージョン作成完了: {ver_id}")
        return ver_id, True
    print("  [FAIL] バージョン作成失敗")
    return None, False


# ─────────────────────────────────────────────
# Step 6: Version Localization 更新
# ─────────────────────────────────────────────
def setup_version_localizations(config, version_id, is_first_version=False):
    print("\n=== Step 6: Version Localization ===")

    existing = api_get(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    existing_map = {}
    if existing and existing.get("data"):
        for loc in existing["data"]:
            existing_map[loc["attributes"]["locale"]] = loc["id"]

    localization_ids = {}
    for loc_config in config.get("versionLocalizations", []):
        locale = loc_config["locale"]
        attrs = {}
        allowed_keys = ["description", "keywords", "whatsNew", "promotionalText", "marketingUrl", "supportUrl"]
        if is_first_version:
            allowed_keys.remove("whatsNew")
        for key in allowed_keys:
            if key in loc_config and loc_config[key] is not None:
                attrs[key] = loc_config[key]

        if locale in existing_map:
            loc_id = existing_map[locale]
            payload = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc_id,
                    "attributes": attrs,
                }
            }
            result = api_patch(f"/v1/appStoreVersionLocalizations/{loc_id}", payload)
            if result:
                print(f"  [{locale}] 更新完了")
                localization_ids[locale] = loc_id
            else:
                print(f"  [{locale}] [WARN] 更新失敗（続行）")
        else:
            payload = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {**attrs, "locale": locale},
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version_id}
                        }
                    },
                }
            }
            result = api_post("/v1/appStoreVersionLocalizations", payload)
            if result:
                loc_id = result["data"]["id"]
                print(f"  [{locale}] 作成完了: {loc_id}")
                localization_ids[locale] = loc_id
            else:
                print(f"  [{locale}] [WARN] 作成失敗（続行）")

    return localization_ids


# ─────────────────────────────────────────────
# Step 7: 審査情報 設定
# ─────────────────────────────────────────────
def setup_review_detail(config, version_id):
    print("\n=== Step 7: 審査情報 ===")
    review = config.get("reviewDetail", {})
    if not review:
        print("  reviewDetail が未設定（スキップ）")
        return

    attrs = {}
    for key in [
        "contactFirstName", "contactLastName", "contactEmail", "contactPhone",
        "demoAccountName", "demoAccountPassword", "demoAccountRequired", "notes",
    ]:
        if key in review:
            attrs[key] = review[key]

    # 既存チェック
    existing = api_get(f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail")
    if existing and existing.get("data"):
        detail_id = existing["data"]["id"]
        payload = {
            "data": {
                "type": "appStoreReviewDetails",
                "id": detail_id,
                "attributes": attrs,
            }
        }
        result = api_patch(f"/v1/appStoreReviewDetails/{detail_id}", payload)
        if result:
            print("  審査情報更新完了")
        else:
            print("  [WARN] 審査情報更新失敗（続行）")
        return

    # 新規作成
    payload = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id}
                }
            },
        }
    }
    result = api_post("/v1/appStoreReviewDetails", payload)
    if result:
        print("  審査情報設定完了")
    else:
        print("  [WARN] 審査情報設定失敗（続行）")


# ─────────────────────────────────────────────
# Step 8: IAP 作成
# ─────────────────────────────────────────────
def create_iap(config, app_id):
    print("\n=== Step 8: IAP 作成 ===")
    iap_ids = []

    for iap_config in config.get("inAppPurchases", []):
        product_id = iap_config["productId"]
        print(f"  --- {product_id} ---")

        # 既存チェック
        existing = api_get(f"/v1/apps/{app_id}/inAppPurchasesV2", {
            "filter[productId]": product_id,
        })
        if existing and existing.get("data"):
            iap_id = existing["data"][0]["id"]
            print(f"  既存 IAP を使用: {iap_id}")
            iap_ids.append((iap_id, iap_config))
            continue

        # 新規作成
        payload = {
            "data": {
                "type": "inAppPurchases",
                "attributes": {
                    "name": iap_config["name"],
                    "productId": product_id,
                    "inAppPurchaseType": iap_config.get("type", "NON_CONSUMABLE"),
                    "reviewNote": iap_config.get("reviewNote", ""),
                },
                "relationships": {
                    "app": {
                        "data": {"type": "apps", "id": app_id}
                    }
                },
            }
        }
        result = api_post("/v2/inAppPurchases", payload)
        if result:
            iap_id = result["data"]["id"]
            print(f"  IAP 作成完了: {iap_id}")
            iap_ids.append((iap_id, iap_config))
        else:
            print(f"  [FAIL] IAP 作成失敗: {product_id}")

    return iap_ids


# ─────────────────────────────────────────────
# Step 9: IAP ローカリゼーション
# ─────────────────────────────────────────────
def setup_iap_localizations(iap_ids):
    print("\n=== Step 9: IAP ローカリゼーション ===")

    for iap_id, iap_config in iap_ids:
        localizations = iap_config.get("localizations", [])
        if not localizations:
            print(f"  [{iap_id}] localizations 未設定（スキップ）")
            continue

        # 既存取得
        existing = api_get(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")
        existing_map = {}
        if existing and existing.get("data"):
            for loc in existing["data"]:
                existing_map[loc["attributes"]["locale"]] = loc["id"]

        for loc_config in localizations:
            locale = loc_config["locale"]
            attrs = {
                "name": loc_config["name"],
                "description": loc_config.get("description", ""),
            }

            if locale in existing_map:
                loc_id = existing_map[locale]
                payload = {
                    "data": {
                        "type": "inAppPurchaseLocalizations",
                        "id": loc_id,
                        "attributes": attrs,
                    }
                }
                result = api_patch(f"/v1/inAppPurchaseLocalizations/{loc_id}", payload)
                if result:
                    print(f"  [{iap_id}][{locale}] 更新完了")
                else:
                    print(f"  [{iap_id}][{locale}] [WARN] 更新失敗（続行）")
            else:
                payload = {
                    "data": {
                        "type": "inAppPurchaseLocalizations",
                        "attributes": {**attrs, "locale": locale},
                        "relationships": {
                            "inAppPurchaseV2": {
                                "data": {"type": "inAppPurchases", "id": iap_id}
                            }
                        },
                    }
                }
                result = api_post("/v1/inAppPurchaseLocalizations", payload)
                if result:
                    print(f"  [{iap_id}][{locale}] 作成完了")
                else:
                    print(f"  [{iap_id}][{locale}] [WARN] 作成失敗（続行）")


# ─────────────────────────────────────────────
# Step 10: IAP 価格設定
# ─────────────────────────────────────────────
def setup_iap_price(config, iap_ids):
    print("\n=== Step 10: IAP 価格設定 ===")
    target_price = config.get("iapPrice", 500)

    for iap_id, iap_config in iap_ids:
        print(f"  --- {iap_config['productId']} (¥{target_price}) ---")

        # 既存の価格スケジュールチェック
        existing_prices = api_get(
            f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule",
            {"include": "manualPrices", "fields[inAppPurchasePrices]": "startDate"},
        )
        if existing_prices and existing_prices.get("data"):
            print("  価格スケジュール設定済み（スキップ）")
            continue

        # 価格ポイント検索（JPY で target_price に一致するもの）
        price_points = api_get(
            f"/v2/inAppPurchases/{iap_id}/pricePoints",
            {
                "filter[territory]": "JPN",
                "fields[inAppPurchasePricePoints]": "customerPrice,proceeds",
                "limit": 200,
            },
        )
        if not price_points or not price_points.get("data"):
            print("  [WARN] 価格ポイント取得失敗（スキップ）")
            continue

        target_point_id = None
        for pp in price_points["data"]:
            customer_price = pp["attributes"].get("customerPrice")
            if customer_price and float(customer_price) == float(target_price):
                target_point_id = pp["id"]
                break

        if not target_point_id:
            print(f"  [WARN] ¥{target_price} の価格ポイントが見つかりません（スキップ）")
            continue

        print(f"  価格ポイント: {target_point_id}")

        # 価格スケジュール設定
        payload = {
            "data": {
                "type": "inAppPurchasePriceSchedules",
                "relationships": {
                    "inAppPurchase": {
                        "data": {"type": "inAppPurchases", "id": iap_id}
                    },
                    "manualPrices": {
                        "data": [
                            {"type": "inAppPurchasePrices", "id": "${price1}"}
                        ]
                    },
                    "baseTerritory": {
                        "data": {"type": "territories", "id": "JPN"}
                    },
                },
            },
            "included": [
                {
                    "type": "inAppPurchasePrices",
                    "id": "${price1}",
                    "attributes": {
                        "startDate": None,
                    },
                    "relationships": {
                        "inAppPurchasePricePoint": {
                            "data": {
                                "type": "inAppPurchasePricePoints",
                                "id": target_point_id,
                            }
                        },
                    },
                }
            ],
        }
        result = api_post("/v1/inAppPurchasePriceSchedules", payload)
        if result:
            print("  価格設定完了")
        else:
            print("  [WARN] 価格設定失敗（続行）")


# ─────────────────────────────────────────────
# Step 11: スクリーンショットアップロード
# ─────────────────────────────────────────────
def upload_screenshots(config, localization_ids, base_dir):
    print("\n=== Step 11: スクリーンショットアップロード ===")
    screenshot_dir = os.path.join(base_dir, config.get("screenshotDir", "screenshot"))

    if not os.path.exists(screenshot_dir):
        print(f"  スクリーンショットディレクトリが見つかりません: {screenshot_dir}")
        return

    # ja の localization ID を使う
    ja_loc_id = localization_ids.get("ja")
    if not ja_loc_id:
        print("  [WARN] ja の Version Localization ID がありません（スキップ）")
        return

    for device_type, display_type in SCREENSHOT_DISPLAY_TYPES.items():
        device_dir = os.path.join(screenshot_dir, device_type)
        if not os.path.exists(device_dir):
            print(f"  [{device_type}] ディレクトリなし（スキップ）")
            continue

        # PNG ファイルを番号順にソート
        files = sorted(
            [f for f in os.listdir(device_dir) if f.lower().endswith(".png")],
            key=lambda x: x,
        )
        if not files:
            print(f"  [{device_type}] スクリーンショットなし（スキップ）")
            continue

        print(f"\n  [{device_type}] {len(files)} 枚のスクリーンショット")

        # Screenshot Set 作成（既存チェック）
        existing_sets = api_get(
            f"/v1/appStoreVersionLocalizations/{ja_loc_id}/appScreenshotSets",
            {"filter[screenshotDisplayType]": display_type},
        )
        screenshot_set_id = None
        if existing_sets and existing_sets.get("data"):
            screenshot_set_id = existing_sets["data"][0]["id"]
            print(f"  既存 Screenshot Set: {screenshot_set_id}")

            # 既存スクリーンショット枚数チェック
            existing_shots = api_get(
                f"/v1/appScreenshotSets/{screenshot_set_id}/appScreenshots"
            )
            if existing_shots and existing_shots.get("data") and len(existing_shots["data"]) > 0:
                print(f"  既に {len(existing_shots['data'])} 枚アップロード済み（スキップ）")
                continue
        else:
            payload = {
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {
                        "screenshotDisplayType": display_type,
                    },
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {
                                "type": "appStoreVersionLocalizations",
                                "id": ja_loc_id,
                            }
                        }
                    },
                }
            }
            result = api_post("/v1/appScreenshotSets", payload)
            if result:
                screenshot_set_id = result["data"]["id"]
                print(f"  Screenshot Set 作成: {screenshot_set_id}")
            else:
                print(f"  [FAIL] Screenshot Set 作成失敗（スキップ）")
                continue

        # 各画像をアップロード
        for filename in files:
            filepath = os.path.join(device_dir, filename)
            filesize = os.path.getsize(filepath)

            with open(filepath, "rb") as f:
                file_data = f.read()

            md5_digest = hashlib.md5(file_data).hexdigest()

            print(f"    {filename} ({filesize} bytes)...")

            # Reserve
            reserve_payload = {
                "data": {
                    "type": "appScreenshots",
                    "attributes": {
                        "fileName": filename,
                        "fileSize": filesize,
                    },
                    "relationships": {
                        "appScreenshotSet": {
                            "data": {
                                "type": "appScreenshotSets",
                                "id": screenshot_set_id,
                            }
                        }
                    },
                }
            }
            reserve_result = api_post("/v1/appScreenshots", reserve_payload)
            if not reserve_result:
                print(f"    [FAIL] Reserve 失敗: {filename}")
                continue

            screenshot_id = reserve_result["data"]["id"]
            upload_ops = reserve_result["data"]["attributes"].get("uploadOperations", [])

            if not upload_ops:
                print(f"    [WARN] アップロード操作情報なし: {filename}")
                continue

            # Upload（各パートを PUT）
            all_ok = True
            for op in upload_ops:
                url = op["url"]
                offset = op.get("offset", 0)
                length = op.get("length", filesize)
                request_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
                chunk = file_data[offset:offset + length]

                content_type = request_headers.get("Content-Type", "image/png")
                if DRY_RUN:
                    print(f"    [DRY-RUN] PUT {url[:80]}... ({length} bytes)")
                    continue

                resp = requests.put(url, headers=request_headers, data=chunk)
                if resp.status_code not in (200, 201):
                    print(f"    [FAIL] Upload part: {resp.status_code}")
                    all_ok = False
                    break

            if not all_ok:
                continue

            # Commit
            commit_payload = {
                "data": {
                    "type": "appScreenshots",
                    "id": screenshot_id,
                    "attributes": {
                        "uploaded": True,
                        "sourceFileChecksum": md5_digest,
                    },
                }
            }
            commit_result = api_patch(f"/v1/appScreenshots/{screenshot_id}", commit_payload)
            if commit_result:
                print(f"    {filename} アップロード完了")
            else:
                print(f"    [WARN] Commit 失敗: {filename}")


# ─────────────────────────────────────────────
# メイン処理
# ─────────────────────────────────────────────
def main():
    global DRY_RUN

    if len(sys.argv) < 2:
        print("Usage: python3 register_app.py <config.json> [--dry-run] [--app-id APP_ID]")
        sys.exit(1)

    config_path = sys.argv[1]
    DRY_RUN = "--dry-run" in sys.argv

    # --app-id オプション（アプリ作成が API 不可の場合に手動指定）
    forced_app_id = None
    if "--app-id" in sys.argv:
        idx = sys.argv.index("--app-id")
        if idx + 1 < len(sys.argv):
            forced_app_id = sys.argv[idx + 1]

    if DRY_RUN:
        print("🔍 DRY-RUN モード: API コールは実行されません\n")

    # テンプレート読み込み
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)

    base_dir = os.path.dirname(os.path.abspath(config_path))
    # screenshotDir が相対パスの場合、プロジェクトルート基準
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    print(f"=== App Store Connect 自動登録 ===")
    print(f"アプリ名:    {config['app']['name']}")
    print(f"Bundle ID:  {config['app']['bundleId']}")
    print(f"SKU:        {config['app']['sku']}")
    print(f"設定ファイル: {config_path}")

    summary = {}

    # Step 1: Bundle ID
    bundle_id_resource_id = register_bundle_id(config)
    if not bundle_id_resource_id:
        print("\n❌ Bundle ID 登録失敗。中断します。")
        sys.exit(1)
    summary["Bundle ID"] = bundle_id_resource_id

    # Step 2: アプリ作成
    if forced_app_id:
        app_id = forced_app_id
        print(f"\n=== Step 2: アプリ作成 ===")
        print(f"  --app-id で指定: {app_id}")
    else:
        app_id = create_app(config, bundle_id_resource_id)
        if not app_id:
            print("\n❌ アプリ作成失敗。中断します。")
            print("  App Store Connect Web で手動作成後、--app-id オプションで再実行してください。")
            sys.exit(1)
    summary["App ID"] = app_id

    # Step 3: App Info (カテゴリ設定)
    app_info_id = setup_app_info(config, app_id)
    if app_info_id:
        summary["App Info ID"] = app_info_id

        # Step 4: App Info Localization
        setup_app_info_localizations(config, app_info_id)

    # Step 5: Version 作成
    version_id, is_first_version = create_version(config, app_id)
    if version_id:
        summary["Version ID"] = version_id

        # Step 6: Version Localization
        localization_ids = setup_version_localizations(config, version_id, is_first_version)

        # Step 7: 審査情報
        setup_review_detail(config, version_id)

        # Step 11: スクリーンショット（Version Localization が必要）
        if localization_ids:
            upload_screenshots(config, localization_ids, project_root)

    # Step 8-10: IAP
    iap_ids = create_iap(config, app_id)
    if iap_ids:
        setup_iap_localizations(iap_ids)
        setup_iap_price(config, iap_ids)

    # 完了サマリ
    print("\n" + "=" * 50)
    print("✅ 登録完了サマリ")
    print("=" * 50)
    for key, value in summary.items():
        print(f"  {key}: {value}")
    print()


if __name__ == "__main__":
    main()
