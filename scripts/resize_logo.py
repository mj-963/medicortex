#!/usr/bin/env python3
"""
Resize the MediCortex logo PNG to all required sizes for web deployment.
Uses the logo from assets/images/medicortex_logo.png
"""

from PIL import Image
from pathlib import Path


def resize_logo(source_path, output_path, size):
    """
    Resize logo to specified size while maintaining aspect ratio.

    Args:
        source_path: Path to source PNG file
        output_path: Path to save resized PNG
        size: Target size (width, height) tuple
    """
    img = Image.open(source_path)

    # Use high-quality resampling
    img_resized = img.resize(size, Image.Resampling.LANCZOS)

    # Save with optimization
    img_resized.save(output_path, optimize=True)
    print(f"✓ Saved: {output_path} ({size[0]}x{size[1]}px)")


def main():
    """Resize logo to all required sizes for web deployment."""

    # Source logo
    source = Path(__file__).parent.parent / 'assets' / 'images' / 'medicortex_logo.png'

    if not source.exists():
        print(f"❌ Error: Source logo not found at {source}")
        return

    # Output directories
    web_dir = Path(__file__).parent.parent / 'web'
    icons_dir = web_dir / 'icons'
    icons_dir.mkdir(exist_ok=True)

    print(f"Resizing logo from: {source}\n")

    # Define all required sizes
    sizes = [
        # Favicons
        ((16, 16), web_dir / 'favicon-16x16.png'),
        ((32, 32), web_dir / 'favicon.png'),

        # PWA icons
        ((192, 192), icons_dir / 'Icon-192.png'),
        ((512, 512), icons_dir / 'Icon-512.png'),
        ((1024, 1024), icons_dir / 'Icon-1024.png'),

        # Transparent versions for splash screens
        ((512, 512), icons_dir / 'Icon-512-transparent.png'),
        ((1024, 1024), icons_dir / 'Icon-1024-transparent.png'),
    ]

    for size, path in sizes:
        resize_logo(source, path, size)

    print(f"\n✓ All icons generated successfully!")
    print(f"\nGenerated files in:")
    print(f"  - {web_dir}")
    print(f"  - {icons_dir}")


if __name__ == '__main__':
    main()
