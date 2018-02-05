#
# Copyright 2017-2018 (c) Andrey Galkin
#


type Cfsystem::Keygenopts = Struct[{
    'type' => Cfsystem::Keytype,
    'bits' => Cfsystem::Rsabits,
}]
