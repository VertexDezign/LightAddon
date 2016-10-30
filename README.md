# LightAddon

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
Giants, itzc0br4 - Fire-Technology