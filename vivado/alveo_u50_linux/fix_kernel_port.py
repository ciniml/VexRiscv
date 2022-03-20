#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import sys

def fix_port(node: ET.Element):
    if node.tag == 'port':
        if node.attrib.get('name') == 's_axi_control':
            node.attrib['range'] = '0x10000'
    else:
        for child in node:
            fix_port(child)
target = sys.argv[1]
tree = ET.parse(target)
root = tree.getroot()
fix_port(root)
tree.write(target, encoding='utf-8', xml_declaration=True)
