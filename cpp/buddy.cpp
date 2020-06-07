#include <iostream>
using namespace std;


struct buddy_system
{
	static constexpr int min_exp = 6;
	static constexpr int max_exp = 10;
	int free_buddy[max_exp - min_exp + 1]{}; //durch geschweifte Klammern mit 0 initialisiert


	buddy_system(){
		free_buddy[max_exp - min_exp] = 1;
	}


	int allocate (int expo){
		if (max_exp < expo || expo < min_exp)
		{
			return 0;
		}
		//index = start bucket, für korrekten exponent der zweierpotenz
		const int index = expo - min_exp;
		//wenn größerer exponent gefunden, split notwendig
		int split_index = 0;
		for (int i = index; i <= max_exp - min_exp; ++i)
		{
			if (free_buddy[i] != 0)
				{
					split_index = i;
					break;
				}	
		}
		if (split_index == 0)
		{
			return 0;
		}
		const int result = free_buddy[split_index];
		free_buddy[split_index] = 0;
		//nächst niedriger ex, split
		for (int i = split_index-1; i >= index; --i)
		{
			//1+2⁹, shift nach links (bsp. 0011 -> 0110)
			free_buddy[i] = result + (1<<(min_exp + i));
		}
		return result;

		return 0;

	}

};

ostream& operator<<(ostream& os, const buddy_system& bs) {
	for (int i = 0; i <= bs.max_exp - bs.min_exp; ++i)
	{
		os << bs.free_buddy[i] << "\t";
	}
	return os << "\n";
}


int main (){

	buddy_system var {};
	cout << var;
	int first = var.allocate(8);
	cout << "var.allocate(8) = " << first << "\n" << var;
	first = var.allocate(7);
	cout << "var.allocate(7) = " << first << "\n" << var;
	first = var.allocate(8);
	cout << "var.allocate(8) = " << first << "\n" << var;
	first = var.allocate(9);
	cout << "var.allocate(9) = " << first << "\n" << var;
	first = var.allocate(6);
	cout << "var.allocate(6) = " << first << "\n" << var;

}