import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// İçeriği geniş ekranlarda ortalayıp genişliğini sınırlar.
class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.maxWidth = 1000});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Genişliğe göre 1 veya 2 sütun.
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({super.key, required this.children, this.gap = 12});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 720 ? 2 : 1;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      });
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Yükleme sırasında boş ekran yerine gösterilen iskelet.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 72, this.radius = 16});
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(p.surface, p.surfaceHigh, _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) => ResponsiveWrap(
        children: [for (var i = 0; i < count; i++) const SkeletonBox()],
      );
}

/// Alış/satış/değişim gibi küçük etiket-değer çifti.
class StatItem extends StatelessWidget {
  const StatItem(this.label, this.value, {super.key, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color ?? p.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabularFigures)),
        ]),
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}
