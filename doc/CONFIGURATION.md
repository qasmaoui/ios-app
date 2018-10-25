# Configuration

## Introduction

The ownCloud iOS App provides a flexible mechanism for configuration. While it currently only returns the default values defined by the classes itself, MDM and branding support can be added in the future with relatively little effort.

This document provides an overview over the available sections and variables.

## Bookmarks

- **Section ID**: `bookmark`

- **Variables**:
	- `default-url`: Set a default server URL.
		- type: String
		- default: `""`
	- `url-editable`: Being able to edit the server URL in the URL TextField.
		- type: Bool
		- default: `true`
	- `url-visible`: Being able to hide the server URL TextField.
		- type: Bool
		- default: `true`
	- `default-name`: Set a default server name.
		- type: String
		- default: `""`
	- `name-editable`: Being able to edit the server name in the name TextField.
		- type: Bool
		- default: `true`
	- `name-visible`: Being able to hide the server name TextField.
		- type: Bool
		- default: `true`