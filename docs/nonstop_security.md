# Nonstop Security

## Gateway

Gateways are the public endpoints, the first line of defense.
Their only publicly visible port is 80 and 443 for http(s) communication.

If the correct port knocking sequence is executed, they allow incoming ssh connections.
Other connection attempts to ssh are simply dropped.

	broker                 ~ internet ~                 gateway
	|                                                         |
	|                                                         |
	| TCP-SYN PORT1                                           |
	|-------------------------------------------------------->|
	| TCP-SYN PORT2                                           |
	|-------------------------------------------------------->|
	| TCP-SYN PORT3                                           |
	|-------------------------------------------------------->|
	| TCP-SYN …                                               |
	|-------------------------------------------------------->| correct!
	| SSH PORT FORWARD                                        |
	|========================================================>| I can haz redis!
	|<========================================================|
	|                                                         |

## Broker

Brokers are machines that live elsewere than Gateways. Their location is not publicly known. They are the second line of defense.
If someone breaks into a gateway, he may acquire the public IP of a broker.

* Brokers expose Redis to Gateways by port forwarding via ssh tunnels.

* Before a Broker may create an ssh tunnel to a Gateway, it must execute the correct port knocking sequence.

* Brokers do not expose any port publicly.

* Sensitive information may only pass Brokers, nothing is stored.

* Brokers live in the same private network as the Core.

* Brokers validate incoming requests from the queue


## Core

The core machines are similar to brokers, except they are even less connected to the outer world.

* Core machines only require a private network to talk to brokers.

* All sensitive information is being stored on Core machines.

* Database lives on Core machines.
