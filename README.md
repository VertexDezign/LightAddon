# LightAddon

[![ModHub Download](https://img.shields.io/badge/ModHub-2.0.1.0-blue.svg?style=flat-square)](https://farming-simulator.com/mod.php?lang=de&country=ch&mod_id=53564&title=fs2017)

## Features

- Global Script
- Strobelights
- Day drive Lights
- Turnlights reset

## Example XML Entry

```xml
<LightAddon drlAllwaysOn="true">
    <drl decoration="0>2|9|0" realLight="0>2|9|1"/>
    <strobe decoration="0>2|8|0|0" realLight="0>2|8|0|1" isBeacon="true" />
    <strobe decoration="0>2|8|1|0" realLight="0>2|8|1|1" isBeacon="true" />
    <strobe decoration="0>2|7|0|0" realLight="0>2|7|0|1" isBeacon="false" name="SampleStrobe1" sequence="200 400" invert="false" />
    <strobe decoration="0>2|7|1|0" realLight="0>2|7|1|1" isBeacon="false" name="SampleStrobe1" sequence="400 200" invert="true" />
</LightAddon>
```

## Credits
Grisu118 - VertexDezign
### Sample Mod
Giants, Fire-Technology

#LICENSE
Copyright (c) 2016-2018 VertexDezign All rights reserved.  
Copyright (c) 2016-2018 Benjamin Leber All rights reserved.

This copyright does not impugn any trademarks or copyrights owned by Giants

Warranty disclaimer. You agree that you are using the software solely at your own risk.
VertexDezign provides the software “as is” and without warranty of any kind, and VertexDezign
for itself and its publishers and licensors hereby disclaims all express or implied warranties,
including without limitation warranties of merchantability, fitness for a particular purpose,
performance, accuracy, reliability, and non-infringement.

The Terms and Conditions of GIANTS Software GmbH also apply.

##Informal explanation

An informal explanation of what this all means (this part is not legalese and can't be treated as such)

VertexDezign (we) wrote the Mod and we have the copyright on this Mod. That means the code is ours and we can
do with it what we want. It also means you can't just copy our code and use it for your own projects. 
Only we can distribute the Mod to others. We allow you to make small changes for your own gameplay or with your friends.
But you are not allowed to publish these changes openly. When you make a contribution (translations, code changes) you
give that code to us. Otherwise we would not be able to publish this Mod anymore.
If you lose your savegame or if your computer crashes due to our Mod, you can tell us and we will attempt to fix the
mod but we will not be paying for a new computer nor getting your savegame back. (Make backups!)