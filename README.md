# Cross-service-inventory
A project to identify if devices appear in multiple inventory (or security agent) systems with a simple PowerShell script. Starting with Lansweeper, Sophos, and Heimdal.

# Introduction
Taking inspiration from CIS Critical Security Controls 1 & 2 this script takes CSV exports from the [Lansweeper](https://www.lansweeper.com/), [Sophos](https://www.sophos.com/), and [Heimdal](https://heimdalsecurity.com/) management consoles to then determine what systems a unique hostname is missing from.

https://www.cisecurity.org/controls/inventory-and-control-of-enterprise-assets
https://www.cisecurity.org/controls/inventory-and-control-of-software-assets

# Thoughts for improvement
* Login to the API for each service and extract the data.
* Add in other inventory/security agent systems.
  * Palo Alto Networks Cortex XDR.
* Find a better Lansweeper report for the source data to handle Linux systems.
