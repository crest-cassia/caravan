# Dump format of CARAVAN

All of these variables are stored in the Network-Byte Order (Big-Endian).

## Format of TaskResult

| Name | byte | type | repeat |
|:------|:------|:------|:--------|
| taskId | 8 | Long | 1 |
| rc     | 8 | Long | 1 |
| placeId | 8 | Long | 1 |
| startAt | 8 | Long | 1 |
| finishAt | 8 | Long | 1 |
| numResults | 8 | Long | 1 |
| results | 8*numResults | Double | numResults |

