import 'package:folio/models/release.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_tile.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_dialog.dart';
import 'package:flutter/material.dart';

class UpdateViewable extends StatelessWidget {
  const UpdateViewable(this.release, {super.key});

  final Release release;

  @override
  Widget build(BuildContext context) {
    return UpdateTile(
      release,
      onTap: () => UpdateDialog.show(context, release),
    );
  }
}
