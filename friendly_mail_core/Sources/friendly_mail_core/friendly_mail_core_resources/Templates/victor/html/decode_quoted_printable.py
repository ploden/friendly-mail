import quopri
import sys

if __name__ == '__main__':
    try:
        filename = sys.argv[1]
        f = open(filename, 'r', encoding="utf-8")
        contents = f.read()
        f.close()

        decoded_string = quopri.decodestring(contents)
        print(decoded_string.decode('utf-8'))
    except UnicodeDecodeError:
        filename = sys.argv[1]
        f = open(filename, 'r', encoding="utf-8")
        contents = f.read()
        f.close()

        decoded_string = quopri.decodestring(contents)
        print(decoded_string.decode('latin1'))

