//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"


let pwd = "123456"

let pass :[UInt8] = Array<UInt8>(pwd.utf8)

for c in pwd.utf8{
    print(c)
}