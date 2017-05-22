
// XferType
enum XferType 
{	
    GetSize,
    In,
    Out,
	HttpIn
};



////////////////////////////////////////////////////////////////////////
//	XferDWord
////////////////////////////////////////////////////////////////////////

inline int XferDWord(unsigned int *pdw, XferType xType, void *pv)
	{
#pragma warning (disable : 4062 )
	switch(xType) {
		case ::In:	*pdw = *(unsigned int *) pv;	break;
		case ::Out:	*(unsigned int *) pv = *pdw;	break;
		}
#pragma warning (default : 4062 )

	return(sizeof(unsigned int));
	}




////////////////////////////////////////////////////////////////////////
//	XferQWord - Transfer QuadWord -for 64 bit values
////////////////////////////////////////////////////////////////////////

inline int XferQWord(unsigned __int64 *pqw, XferType xType, void *pv)
	{
#pragma warning (disable : 4062 )
	switch(xType) {
		case ::In:	*pqw = *(unsigned __int64 *) pv;	break;
		case ::Out:	*(unsigned __int64 *) pv = *pqw;	break;
		}
#pragma warning (default : 4062 )

	return(sizeof(unsigned __int64));
	}




class XRID	// xrid
{
private: // use accessors:

	// Pointer to the XRAtom containing the transaction information.
	union
	{
		void * m_pv;
		unsigned int m_dwAtom;
		unsigned __int64 m_ullAtom;
	};

	// A generation count is used to uniquely identify a transaction.  The
	// generation count is bumped everytime the XRAtom is free'd to the XRHeap,
	// so that no transaction requested by a thread from a previous generation
	// atom will ever get confused about a current generation transaction.
	unsigned int m_cGeneration;

public:
	XRID::XRID() : m_cGeneration(0)
	{
		m_ullAtom = 0;
	}
	XRID::XRID(unsigned __int64 _ullAtom, unsigned int dwGeneration) : 
		m_cGeneration(dwGeneration)
	{
		m_ullAtom = _ullAtom;
	}
//	XRID::~XRID() {}

	void Clear()
	{
		m_ullAtom = 0;
		m_cGeneration = 0;
	}

	unsigned int GetGeneration() const
	{
		return m_cGeneration;
	}
	void SetGeneration( unsigned int _cGeneration )
	{
		m_cGeneration = _cGeneration;
	}

	void * PXRAtom() const
	{
		return m_pv;
	}
	void SetPXRAtom( void * _pv )
	{
#ifdef _M_IX86
		m_ullAtom = 0;	// Ensure upper DWORD cleared on 32bit.
#endif _M_IX86
		m_pv = _pv;
	}
	unsigned int DwXRAtom() const
	{
		return m_dwAtom;
	}
	void SetDwXRAtom( unsigned int _dwAtom )
	{
		m_ullAtom = 0;
		m_dwAtom = _dwAtom;
	}
	unsigned __int64 UllXRAtom() const
	{
		return m_ullAtom;
	}
	void SetUllXRAtom( unsigned __int64 _ullAtom )
	{
		m_ullAtom = _ullAtom;
	}

	unsigned int Xfer(XferType xType, void* pv, unsigned int _dwVersion);

	bool IsValid() const 
	{ 
		return m_ullAtom != 0;
	}
	bool FIsNullXRID() const
	{
		return 0 == m_ullAtom;
	}
	void SetXRIDNull()
	{
		m_ullAtom = 0;
	}

	bool operator !() const
	{
		return !m_ullAtom;
	}
	bool operator == ( XRID const & _r ) const
	{
		return m_ullAtom == _r.m_ullAtom;
	}
};
