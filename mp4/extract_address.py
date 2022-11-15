from collections import Counter
import sys

def parse_data(filename):
    with open(filename) as fp:
        lines = fp.readlines()	
    filtered_lines = [line[line.rfind("=")+1:].strip() for line in lines if line.strip().startswith("a_pmem_address")]
    
    address_counter = Counter(filtered_lines)

    distinct_addresses = [key for key in address_counter.keys() if key != "x" and key != "0"]

    filtered_lines = [addr for addr in filtered_lines if addr != "0" and addr != "x"]

    print("Number of total addressess (excluding 0 and x) is {}".format(len(filtered_lines)))    

    print("Number of distinct non-zero and non-x addresses is {}".format(len(distinct_addresses)))
if __name__ == "__main__":
    parse_data(sys.argv[1])
