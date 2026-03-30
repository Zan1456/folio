import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:folio/api/providers/status_provider.dart';
import 'status_bar.i18n.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  StatusBarState createState() => StatusBarState();
}

class StatusBarState extends State<StatusBar> {
  late StatusProvider statusProvider;

  @override
  Widget build(BuildContext context) {
    statusProvider = Provider.of<StatusProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    Status? currentStatus = statusProvider.getStatus();
    final bool visible = currentStatus != null;

    Color barColor;
    Color textColor;
    Color progressColor;

    switch (currentStatus) {
      case Status.maintenance:
      case Status.apiError:
        barColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        progressColor = colorScheme.error;
        break;
      case Status.network:
        barColor = colorScheme.surfaceContainerHigh;
        textColor = colorScheme.onSurface.withValues(alpha: 0.7);
        progressColor = colorScheme.outline;
        break;
      case Status.syncing:
      default:
        barColor = colorScheme.surfaceContainerHigh;
        textColor = colorScheme.onSurface.withValues(alpha: 0.7);
        progressColor = colorScheme.secondary;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: visible ? 40.0 : 0.0,
      margin: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 4.0),
      child: visible
          ? Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(36.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Progress fill
                  if (currentStatus == Status.syncing)
                    LayoutBuilder(
                      builder: (context, constraints) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: constraints.maxWidth * statusProvider.progress,
                        decoration: BoxDecoration(
                          color: progressColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(36.0),
                        ),
                      ),
                    ),

                  // Status text + icon
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentStatus == Status.syncing) ...[
                          RepaintBoundary(
                            child: SizedBox(
                              width: 12.0,
                              height: 12.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: progressColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                        ] else if (currentStatus == Status.maintenance ||
                            currentStatus == Status.apiError) ...[
                          Icon(Icons.warning_rounded,
                              size: 14.0, color: textColor),
                          const SizedBox(width: 6.0),
                        ] else if (currentStatus == Status.network) ...[
                          Icon(Icons.wifi_off_rounded,
                              size: 14.0, color: textColor),
                          const SizedBox(width: 6.0),
                        ],
                        Text(
                          _statusString(currentStatus),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.0,
                          ),
                        ),
                        if (currentStatus == Status.syncing) ...[
                          const SizedBox(width: 8.0),
                          Text(
                            '${(statusProvider.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  String _statusString(Status? status) {
    switch (status) {
      case Status.syncing:
        return "Syncing data".i18n;
      case Status.maintenance:
        return "KRETA Maintenance".i18n;
      case Status.apiError:
        return "KRETA API error".i18n;
      case Status.network:
        return "No connection".i18n;
      default:
        return "";
    }
  }

}
