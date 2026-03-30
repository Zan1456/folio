/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// ignore_for_file: use_build_context_synchronously

import 'package:folio/models/linked_account.dart';
import 'package:flutter/material.dart';

class ThirdPartyProvider with ChangeNotifier {
  late List<LinkedAccount> _linkedAccounts;
  List<LinkedAccount> get linkedAccounts => _linkedAccounts;
  ThirdPartyProvider();
}
