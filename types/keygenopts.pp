#
# Copyright 2017 (c) Andrey Galkin
#


type Cfsystem::Keygenopts = Struct[{
    'type' => Cfsystem::Keytype,
    'bits' => Cfsystem::Rsabits,
}]
