# LightAddon

[![ModHub Download]https://img.shields.io/badge/ModHub-2.0.1.0-blue.svg?style=flat-square](https://farming-simulator.com/mod.php?lang=de&country=ch&mod_id=53564&title=fs2017)

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