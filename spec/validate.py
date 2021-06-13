#!/usr/bin/env python3

import jsonschema
import json
import sys

def validate_json_with_schema(json_path, schema_path):
    json_file = open(json_path, "r")
    schema_file = open(schema_path, "r")

    instance = json.load(json_file)
    schema = json.load(schema_file)

    jsonschema.validate(instance=instance, schema=schema)
    return True

def main(argv):
    if len(argv) < 3:
        print("Usage: %s schema object" % (sys.argv[0], ))
        return 1

    sch = sys.argv[1]
    obj = sys.argv[2]

    validate_json_with_schema(obj, sch)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
