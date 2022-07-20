import quopri
import sys

if __name__ == '__main__':
    filename = sys.argv[1]
    f = open(filename, 'r')
    contents = f.read()

    decoded_string = quopri.decodestring(contents)
    print(decoded_string.decode('utf-8'))
