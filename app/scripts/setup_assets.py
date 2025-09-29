#!/usr/bin/env python3
"""
灵衍天纪 - 资源文件设置脚本
用于下载项目所需的字体文件和其他资源
"""

import os
import urllib.request
import urllib.error
import sys
from pathlib import Path

def download_file(url, local_path, description):
    """下载文件到指定路径"""
    try:
        print(f"正在下载: {description}")
        print(f"URL: {url}")
        print(f"保存到: {local_path}")
        
        # 确保目录存在
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        
        # 设置请求头以模拟浏览器
        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
        )
        
        # 下载文件
        with urllib.request.urlopen(req) as response:
            with open(local_path, 'wb') as f:
                f.write(response.read())
        
        print(f"✅ 下载完成: {local_path}")
        return True
    except Exception as e:
        print(f"❌ 下载失败 {description}: {e}")
        return False

def create_placeholder_files():
    """创建占位符文件"""
    project_root = Path(__file__).parent.parent
    assets_dir = project_root / "assets"
    
    directories = [
        "images/characters",
        "images/techniques", 
        "images/pills",
        "images/companions",
        "images/realms",
        "images/artifacts",
        "images/sects",
        "images/ui",
        "animations/cultivation",
        "animations/alchemy",
        "animations/effects"
    ]
    
    for directory in directories:
        dir_path = assets_dir / directory
        gitkeep_file = dir_path / ".gitkeep"
        if not gitkeep_file.exists():
            os.makedirs(dir_path, exist_ok=True)
            with open(gitkeep_file, 'w', encoding='utf-8') as f:
                f.write("# This file ensures the directory is tracked by git\n")
            print(f"创建占位符: {gitkeep_file}")

def main():
    """主函数"""
    print("=== 灵衍天纪资源设置工具 ===")
    
    # 项目根目录
    project_root = Path(__file__).parent.parent
    assets_dir = project_root / "assets"
    fonts_dir = assets_dir / "fonts"
    
    print(f"项目根目录: {project_root}")
    print(f"资源目录: {assets_dir}")
    
    # 创建目录结构和占位符文件
    print("\n创建目录结构...")
    create_placeholder_files()
    
    # 字体文件下载配置
    font_downloads = [
        {
            "url": "https://fonts.gstatic.com/s/notosanssc/v36/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYxNbPzS5HE.woff2",
            "path": fonts_dir / "NotoSansSC-Regular.woff2",
            "description": "思源黑体 SC 常规字重 (woff2格式)"
        },
        {
            "url": "https://fonts.gstatic.com/s/notosanssc/v36/k3kJo84MPvpLmixcA63oeALZKaRwRCdKpJ8FbKShZXJI0vQ.woff2", 
            "path": fonts_dir / "NotoSansSC-Bold.woff2",
            "description": "思源黑体 SC 粗体字重 (woff2格式)"
        }
    ]
    
    print("\n=== 字体文件下载 ===")
    
    success_count = 0
    for font in font_downloads:
        if download_file(font["url"], font["path"], font["description"]):
            success_count += 1
    
    # 转换 woff2 到 ttf 的说明
    print(f"\n=== 下载完成统计 ===")
    print(f"成功下载: {success_count}/{len(font_downloads)} 个字体文件")
    
    if success_count > 0:
        print("\n⚠️  注意事项：")
        print("1. 下载的字体为 woff2 格式，Flutter 推荐使用 TTF 格式")
        print("2. 你可能需要将 woff2 转换为 TTF 格式，或者直接从官方下载 TTF 文件")
        print("3. 推荐直接从 Google Fonts 或 Adobe 官网下载思源黑体 TTF 文件")
        print("\n替代下载地址：")
        print("- Google Fonts: https://fonts.google.com/noto/specimen/Noto+Sans+SC")
        print("- Adobe 思源黑体: https://github.com/adobe-fonts/source-han-sans")
    
    print("\n=== 资源目录创建完成 ===")
    print("资源目录结构已创建完成，包含以下目录：")
    print("- assets/images/ (各类图片资源)")
    print("- assets/animations/ (动画文件)")  
    print("- assets/fonts/ (字体文件)")
    
    print("\n📝 下一步操作：")
    print("1. 将所需的图片、动画和字体文件放入相应目录")
    print("2. 确保字体文件为 TTF 格式并正确命名")
    print("3. 运行 'flutter pub get' 刷新依赖")
    print("4. 运行 'flutter clean' 清理构建缓存")

if __name__ == "__main__":
    main()