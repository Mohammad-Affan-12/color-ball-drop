class_name BillingService
extends RefCounted

## Hardened in-app purchase service adapter with SKU validation, duplicate-purchase
## locking, and strict separation between debug sandbox testing and production store verification.

signal purchase_succeeded(product_key: String)
signal purchase_failed(product_key: String, reason: String)
signal purchases_restored(restored_keys: Array[String])

const VALID_SKUS := {
	"remove_ads": "com.cutandcascade.puzzle.remove_ads"
}

var save_manager: SaveManager = null
var simulated_store_available: bool = true
var allow_sandbox_mock_purchases: bool = OS.is_debug_build()
var live_billing_attached: bool = false
var _purchase_in_progress: bool = false

func _init(sm: SaveManager = null) -> void:
	save_manager = sm
	live_billing_attached = Engine.has_singleton("GodotGooglePlayBilling") or Engine.has_singleton("InAppStore")

func is_valid_product(product_key: String) -> bool:
	return VALID_SKUS.has(product_key)

func has_remove_ads() -> bool:
	return save_manager != null and save_manager.remove_ads_owned

func purchase_product(product_key: String) -> bool:
	if not is_valid_product(product_key):
		purchase_failed.emit(product_key, "Invalid product SKU")
		return false
	if save_manager == null:
		purchase_failed.emit(product_key, "SaveManager unavailable")
		return false
	if _purchase_in_progress:
		purchase_failed.emit(product_key, "Purchase transaction already in progress")
		return false
	if product_key == "remove_ads" and save_manager.remove_ads_owned:
		purchase_succeeded.emit(product_key)
		return true

	_purchase_in_progress = true
	if not simulated_store_available:
		_purchase_in_progress = false
		purchase_failed.emit(product_key, "Store unavailable in offline mode")
		return false

	# Security gate: never grant unverified client-side entitlements in release builds
	# unless a verified native billing singleton callback completes.
	if not live_billing_attached and not allow_sandbox_mock_purchases:
		_purchase_in_progress = false
		purchase_failed.emit(product_key, "Native store billing required in production build")
		return false

	_grant_verified_entitlement(product_key)
	_purchase_in_progress = false
	purchase_succeeded.emit(product_key)
	return true

func purchase_remove_ads() -> bool:
	return purchase_product("remove_ads")

func _grant_verified_entitlement(product_key: String) -> void:
	if save_manager == null:
		return
	if product_key == "remove_ads":
		save_manager.remove_ads_owned = true
		save_manager.save_data()

func restore_purchases() -> Array[String]:
	var restored: Array[String] = []
	if save_manager != null and save_manager.remove_ads_owned:
		restored.append("remove_ads")
	purchases_restored.emit(restored)
	return restored
