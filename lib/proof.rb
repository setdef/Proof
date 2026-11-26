# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
#
# SPDX-License-Identifier: MIT
#++

require_relative("proof/version")

# Runs your project's tests and builds on your spare computers.
#
# A project's checks take a computer's time, and the computer you work on
# is the one you least want to spend it on. Proof sends your working tree,
# or any commit, to the Linux, Windows, and macOS computers you have, and
# streams the output back.
#
# This module holds Proof's code. The command, the server, and the runner
# each live under it.
module Proof
end
