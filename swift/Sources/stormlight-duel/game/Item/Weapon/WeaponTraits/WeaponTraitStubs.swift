public struct Thrown: WeaponTrait {
    public var short: Distance
    public var long: Distance
}
public struct Offhand: WeaponTrait {}
public struct Loaded: WeaponTrait {
    public var ammunition: Resource
}
public struct TwoHanded: WeaponTrait {}
public struct Deadly: WeaponTrait {}
public struct CumbersomeWeapon: WeaponTrait {
    public var minStrength: Int
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
