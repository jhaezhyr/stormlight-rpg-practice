public struct Thrown: WeaponTrait {
    var short: Distance
    var long: Distance
}
public struct Offhand: WeaponTrait {}
public struct Loaded: WeaponTrait {
    var ammunition: Resource
}
public struct TwoHanded: WeaponTrait {}
public struct Deadly: WeaponTrait {}
public struct CumbersomeWeapon: WeaponTrait {
    var minStrength: Int
}
public struct Pierce: WeaponTrait {}
public struct Defensive: WeaponTrait {}
public struct UniqueWeapon: WeaponTrait {}
public struct Momentum: WeaponTrait {}
public struct Fragile: WeaponTrait {}
public struct Indirect: WeaponTrait {}
public struct Quickdraw: WeaponTrait {}
public struct Dangerous: WeaponTrait {}
public struct Discreet: WeaponTrait {}
