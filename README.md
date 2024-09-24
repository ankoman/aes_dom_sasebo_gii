# AES_DOM_FOR_GLITCH_EXPERIMENT

## External clk, internal glitcher version
- J8外部クロック50MHz動作
- U5のほうのFPGAの電源いれないと動かない
- もともとのグリッチャーはBUFGを通さないclk_buffered_orgを使ってグリッチ作っているが、めんどくさいので省略

## External glitcher version
- J8外部クロック50MHz動作
- U5のほうのFPGAの電源いれないと動かない


## security-order変更時に変えるところ

- aes_top のN
- VerilogAESWrapperのN
- aes_top_wrapper_vhdlのN
- aes_top_wrapper_vhdlの100行目あたりのCxDO