from collections import Counter
import sys

TAG_BITS = 24
INDEX_BITS = 3

def parse_data(filename):
    with open(filename) as fp:
        lines = fp.readlines()	
    filtered_lines = [line[line.rfind("=")+1:].strip() for line in lines if line.strip().startswith("a_pmem_address")]
    filtered_lines = [int(addr[31:31-TAG_BITS-INDEX_BITS]) for addr in filtered_lines if addr.contains("x") == False]
    #careful, python indexing doesn't include the end index (unlike sys verilog) ;)

    address_counter = Counter(filtered_lines)

    distinct_addresses = [key for key in address_counter.keys() if key != 0]  

    print("Number of distinct non-zero and non-x addresses, which resolve to the same cache line, is {}".format(len(distinct_addresses)))



if __name__ == "__main__":
    parse_data(sys.argv[1])
