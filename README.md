# nodemcu-rfswitch
rfswitch pure-lua module for NodeMCU.

## Usage
Transmit/Receive data using the radio module.

#### Syntax

``` Lua
rfswitch.send(protocol_id, pulse_length, repeat_count, pin, value, length, tx_cb)
rfswitch.recv(pin, rx_cb)
```

#### Parameters
* `protocol_id` positive integer value, from 1-7
* `pulse_length` length of one pulse in microseconds, usually from 300 to 600
* `repeat_count` repeat value, usually from 1 to 5. This is a asynchronous task
* `pin` I/O index of pin, example 6 is for GPIO12
* `value` positive integer value, this is the primary data which will be sent
* `length` bit length of value, if value length is 3 bytes, then length is 24
* `tx_cb()` invoked when send finished
* `rx_cb(protocol_id, value, length)` invoked when receive a data

## Issues
GPIO外部中断任务在NodeMCU处于高负载模式下会被跳过，导致接收到的升降沿错误，无法正确解析数据。连续按下对应按键会增加接收到数据的正确性。实际产品不建议使用此方案解析RF数据。

## Documentation
https://github.com/sui77/rc-switch

https://github.com/nodemcu/nodemcu-firmware/blob/master/app/modules/rfswitch.c
