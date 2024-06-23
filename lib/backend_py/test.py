import os, sys

current_dir = os.path.dirname(os.path.abspath(__file__))
upper_level_dir = os.path.abspath(os.path.join(current_dir, '../../test_py'))
sys.path.append(upper_level_dir)
print(sys.path)