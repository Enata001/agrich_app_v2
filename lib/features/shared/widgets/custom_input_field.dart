import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/theme/app_colors.dart';


class CustomInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsets? contentPadding;
  final String? errorText;
  final String? helperText;

  const CustomInputField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.contentPadding,
    this.errorText,
    this.helperText,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late bool _obscureText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
              padding: const EdgeInsets.all(12),
              child: widget.prefixIcon,
            )
                : null,
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            helperText: widget.helperText,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: widget.enabled ? Colors.white : AppColors.surfaceVariant,
            border: _buildBorder(AppColors.border),
            enabledBorder: _buildBorder(AppColors.border),
            focusedBorder: _buildBorder(AppColors.primaryGreen),
            errorBorder: _buildBorder(AppColors.error),
            focusedErrorBorder: _buildBorder(AppColors.error),
            disabledBorder: _buildBorder(AppColors.borderLight),
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
            helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText && widget.keyboardType != TextInputType.visiblePassword) {
      return IconButton(
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: AppColors.textSecondary,
          size: 20,
        ),
      );
    }

    return widget.suffixIcon != null
        ? Padding(
      padding: const EdgeInsets.all(12),
      child: widget.suffixIcon,
    )
        : null;
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color,
        width: 1.5,
      ),
    );
  }
}

class CustomPhoneInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String initialCountryCode;
  final TextEditingController? controller;
  final void Function(String)? onChanged; // returns E.164
  final String? Function(PhoneNumber?)? validator; // custom validator
  final bool enabled;
  final String? errorText;
  final String? helperText;

  const CustomPhoneInputField({
    super.key,
    this.label,
    this.hint,
    this.initialCountryCode = 'GH',
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.errorText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        IntlPhoneField(
          controller: controller,
          enabled: enabled,
          initialCountryCode: initialCountryCode,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint ?? "Enter phone number",
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            errorText: errorText,
            helperText: helperText,
          ),

          // ✅ Use custom validator if provided, otherwise fallback
          validator: validator ?? (phone) {
            if (phone == null || phone.number.isEmpty) {
              return "Please enter a phone number";
            }

            final number = phone.number;
            switch (phone.countryISOCode) {
              case "GH": // Ghana
                if (number.length != 9) return "Must be 9 digits";
                break;
              case "US": // USA
                if (number.length != 10) return "Must be 10 digits";
                break;
              case "UK": // UK
                if (number.length < 10 || number.length > 11) {
                  return "Must be 10–11 digits";
                }
                break;
              case "NG": // Nigeria
                if (number.length != 10) return "Must be 10 digits";
                break;
              default:
                if (number.length < 6) return "Number too short";
            }

            return null; // ✅ valid
          },

          onChanged: (phone) {
            // ✅ Always returns full E.164 number
            onChanged?.call(phone.completeNumber);
          },
        ),
      ],
    );
  }
}