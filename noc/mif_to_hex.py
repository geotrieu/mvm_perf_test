import argparse
import math
from pathlib import Path

iprec = 8
output_folder = "preload"
extension = ".hex"

iprec_hex_w = math.ceil(iprec / 4)

def tohex2scomplement(signed_int):
    twos_compl = signed_int % (1 << iprec) # convert to 2s complement with fixed length
    return f'{twos_compl:0{iprec_hex_w}x}'

def translate(path):
    pathlist = Path(path).glob('*.mif')
    output_folder_path = Path(path, output_folder)
    output_folder_path.mkdir(exist_ok=True)
    for p in pathlist:
        translated_file_path = Path(output_folder_path, p.stem + extension)
        translated_file = open(translated_file_path, "w")
        with open(p, 'r') as f:
            for row in f:
                weights = row.strip().split(" ")
                for weight in weights:
                    translated_file.write(tohex2scomplement(int(weight)))
                translated_file.write("\n")

if __name__ == "__main__":
    # Parse arguments
    parser = argparse.ArgumentParser(description='Converts a RAD-Sim .mif file using integers to the hex equivalent (Verilog compatible)')
    parser.add_argument('path', metavar='path', type=Path,
                        help='the folder containing the .mif files')
    args = parser.parse_args()

    # Translate
    translate(args.path)