import 'package:flutter/material.dart';

/// Widget carte iOS-style avec effet glassmorphism optionnel
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool glassmorphism;
  final VoidCallback? onTap;
  
  const IOSCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.glassmorphism = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Bouton style iOS moderne
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double iconSize;
  final bool isLoading;
  final bool secondary;
  
  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.iconSize = 20,
    this.isLoading = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? const Color(0xFF8B7DFF);
    
    if (secondary) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: btnColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(btnColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: btnColor, size: iconSize),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: btnColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [btnColor, btnColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: btnColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: textColor ?? Colors.white, size: iconSize),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

/// Badge de statut iOS-style
class IOSStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  
  const IOSStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de texte style iOS
class IOSTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  
  const IOSTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 17,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 17,
                letterSpacing: -0.4,
              ),
              prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: isDark ? Colors.white54 : Colors.black54)
                : null,
              suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    onPressed: onSuffixTap,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
