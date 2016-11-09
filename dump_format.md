# Dump format of CARAVAN

All of these variables are stored in the Network-Byte Order (Big-Endian).

## Format of Table

| Name | byte | type | repeat |
|:------|:------|:------|:--------|
| Simulator.numParams | 8 | Long | 1 |
| Simulator.numOutputs | 8 | Long | 1 |
| numParameterSets | 8 | Long | 1 |
| ParameterSet | 8+8*numParams | --- | numParameterSets |
| numRuns | 8 | Long | 1 |
| Run | 48+8*numOutputs | --- | numRuns |

### Format of ParameterSet

| Name | byte | type | repeat |
|:------|:------|:------|:--------|
| id | 8 | Long | 1 |
| coordinate | 8 | Long | numParams |

### Format of Run

| Name | byte | type | repeat |
|:------|:------|:------|:--------|
| id | 8 | Long | 1 |
| parentPSId | 8 | Long | 1 |
| seed | 8 | Long | 1 |
| result | 8 | Double | numOutputs |
| placeId | 8 | Long | 1 |
| startAt | 8 | Long | 1 |
| finishAt | 8 | Long | 1 |

