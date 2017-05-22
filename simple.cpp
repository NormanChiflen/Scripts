#include <iostream>
#include "simple.h"

unsigned int XRID::Xfer( XferType xType, void* pv, unsigned int _dwVersion )
{
	//Assert( ( 2 == _dwVersion ) || ( 1 == _dwVersion ) );

	char* p=(char*)pv;
	p += XferDWord(&m_cGeneration, xType, p);
	if ( _dwVersion < 2 )
		p += XferDWord( &m_dwAtom, xType, p );
	else
		p += XferQWord( &m_ullAtom, xType, p );
	return  (unsigned int)(p - (char*)pv);
}


int main()
{
	XRID xrid1;
	xrid1.SetDwXRAtom(1);
	xrid1.SetUllXRAtom(1);
	xrid1.SetGeneration(1);
	std::cout << "xrid1.DwXRAtom()[" << xrid1.DwXRAtom() << "]" << std::endl;
	std::cout << "xrid1.UllXRAtom()[" << xrid1.UllXRAtom() << "]" << std::endl;
	std::cout << "xrid1.GetGeneration()[" << xrid1.GetGeneration() << "]" << std::endl;

	unsigned char rgb[8];
	xrid1.Xfer(::Out, rgb, 1);
	XRID xrid2;
	xrid2.SetDwXRAtom(2);
	xrid2.SetUllXRAtom(2);
	xrid2.SetGeneration(2);
	std::cout << "xrid2.DwXRAtom()[" << xrid2.DwXRAtom() << "]" << std::endl;
	std::cout << "xrid2.UllXRAtom()[" << xrid2.UllXRAtom() << "]" << std::endl;
	std::cout << "xrid2.GetGeneration()[" << xrid2.GetGeneration() << "]" << std::endl;

	std::cout << "Xfering in" << std::endl;
	xrid2.Xfer(::In, rgb, 1);

	std::cout << "xrid2.GetGeneration()[" << xrid2.GetGeneration() << "]" << std::endl;
	std::cout << "xrid2.UllXRAtom()[" << xrid2.UllXRAtom() << "]" << std::endl;
	std::cout << "xrid2.DwXRAtom()[" << xrid2.DwXRAtom() << "]" << std::endl;
	std::cout << "xrid1.DwXRAtom()[" << xrid1.DwXRAtom() << "]" << std::endl;

	return 0;
}