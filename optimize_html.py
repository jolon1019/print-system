#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HTML Performance Optimization Script
Optimizes HTML files for faster loading and better performance
"""

import re
import os
from pathlib import Path

def optimize_html(input_file, output_file):
    """Optimize HTML file for performance"""
    
    print(f"Reading file: {input_file}")
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_size = len(content)
    print(f"Original size: {original_size:,} bytes")
    
    # Step 1: Remove HTML comments (except conditional comments)
    print("Step 1: Removing HTML comments...")
    # Keep conditional comments for IE
    content = re.sub(r'<!--(?!\[if).*?-->', '', content, flags=re.DOTALL)
    
    # Step 2: Remove extra whitespace and blank lines
    print("Step 2: Removing extra whitespace...")
    # Remove multiple blank lines
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    # Remove leading/trailing whitespace from lines
    content = re.sub(r'^\s+|\s+$', '', content, flags=re.MULTILINE)
    
    # Step 3: Optimize script loading - add defer/async
    print("Step 3: Optimizing script loading...")
    # Add defer to external scripts (except critical ones)
    content = re.sub(
        r'<script src="(https://unpkg\.com/[^"]+)"></script>',
        r'<script src="\1" defer></script>',
        content
    )
    
    # Step 4: Add lazy loading to images
    print("Step 4: Adding lazy loading to images...")
    # Add loading="lazy" to images (except critical above-the-fold images)
    content = re.sub(
        r'<img(?![^>]*loading=)([^>]*)(?<!loading="lazy")>',
        lambda m: f'<img loading="lazy" {m.group(1)}>',
        content
    )
    
    # Step 5: Add preload hints for critical resources
    print("Step 5: Adding preload hints...")
    # Find the head section
    head_match = re.search(r'<head>(.*?)</head>', content, re.DOTALL)
    if head_match:
        head_content = head_match.group(1)
        
        # Add preload for critical CSS
        preload_tags = []
        css_files = re.findall(r'<link rel="stylesheet" href="([^"]+)"', head_content)
        for css_file in css_files[:2]:  # Preload first 2 CSS files
            preload_tags.append(f'<link rel="preload" href="{css_file}" as="style">')
        
        # Add preload for critical JS
        js_files = re.findall(r'<script src="([^"]+)"', head_content)
        for js_file in js_files[:2]:  # Preload first 2 JS files
            if not js_file.startswith('https://'):
                preload_tags.append(f'<link rel="preload" href="{js_file}" as="script">')
        
        # Insert preload tags at the beginning of head
        if preload_tags:
            new_head = head_content.replace(
                '<meta name="viewport"',
                '\n'.join(preload_tags) + '\n    <meta name="viewport"'
            )
            content = content.replace(head_content, new_head)
    
    # Step 6: Add resource hints
    print("Step 6: Adding resource hints...")
    # Add dns-prefetch for external domains
    external_domains = set(re.findall(r'https://([^/]+)', content))
    dns_hints = []
    for domain in external_domains:
        if domain not in ['localhost', '127.0.0.1']:
            dns_hints.append(f'<link rel="dns-prefetch" href="//{domain}">')
    
    if dns_hints:
        content = re.sub(
            r'<head>',
            '<head>\n    ' + '\n    '.join(dns_hints),
            content
        )
    
    # Step 7: Minify inline CSS (basic)
    print("Step 7: Minifying inline CSS...")
    # Remove CSS comments
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    # Remove extra whitespace in CSS
    content = re.sub(r'\s*([{};:,])\s*', r'\1', content)
    
    # Step 8: Add cache control meta tags
    print("Step 8: Adding cache control meta tags...")
    cache_meta = '''
    <meta http-equiv="Cache-Control" content="max-age=31536000, public">
    <meta http-equiv="Expires" content="0">'''
    
    content = re.sub(
        r'<meta name="viewport" content="([^"]+)">',
        f'<meta name="viewport" content="\\1">{cache_meta}',
        content
    )
    
    # Calculate optimization results
    optimized_size = len(content)
    reduction = original_size - optimized_size
    reduction_percent = (reduction / original_size) * 100
    
    print(f"\nOptimization Results:")
    print(f"  Original size: {original_size:,} bytes")
    print(f"  Optimized size: {optimized_size:,} bytes")
    print(f"  Reduction: {reduction:,} bytes ({reduction_percent:.2f}%)")
    
    # Write optimized content
    print(f"\nWriting optimized file: {output_file}")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Optimization complete!")
    return {
        'original_size': original_size,
        'optimized_size': optimized_size,
        'reduction': reduction,
        'reduction_percent': reduction_percent
    }

if __name__ == '__main__':
    input_file = r'd:\print-system\hot-coil-print-system\main.html'
    output_file = r'd:\print-system\hot-coil-print-system\main_optimized.html'
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found!")
        exit(1)
    
    results = optimize_html(input_file, output_file)
    
    print(f"\n📊 Performance Improvement Summary:")
    print(f"  File size reduced by {results['reduction']:,} bytes")
    print(f"  Compression ratio: {results['reduction_percent']:.2f}%")
    print(f"  Output file: {output_file}")
