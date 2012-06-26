from os import listdir
import subprocess

def compile():
    SOURCE_DIR = "extension/src/"
    TARGET_DIR = "extension/build/"

    COFFE_COMPILE_CMD = "coffee -c -o {0} {1}/{2}"

    for src_file in listdir(SOURCE_DIR):
        c_cmd = COFFE_COMPILE_CMD.format(TARGET_DIR, SOURCE_DIR, src_file)
        subprocess.call(c_cmd, shell=True)

if __name__ == "__main__":
    compile()

