import React, { useState, useEffect } from 'react';

const Button = ({ onClick, children }) => (
  <button onClick={onClick} style={{
    padding: '10px 15px',
    margin: '5px',
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    borderRadius: '5px',
    cursor: 'pointer'
  }}>
    {children}
  </button>
);

const Card = ({ title, children }) => (
  <div style={{
    border: '1px solid #ddd',
    borderRadius: '5px',
    padding: '15px',
    margin: '10px',
    backgroundColor: '#f9f9f9'
  }}>
    <h3>{title}</h3>
    {children}
  </div>
);

const DiscountApp = () => {
  const [brands, setBrands] = useState([]);
  const [promotions, setPromotions] = useState([]);
  const [selectedBrand, setSelectedBrand] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      try {
        const brandsResponse = await fetch('http://localhost:5000/api/brands');
        const brandsData = await brandsResponse.json();
        setBrands(brandsData);

        const promotionsResponse = await fetch('http://localhost:5000/api/promotions');
        const promotionsData = await promotionsResponse.json();
        setPromotions(promotionsData);

        setError(null);
      } catch (err) {
        setError('Failed to fetch data. Please try again later.');
        console.error('Error fetching data:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredPromotions = selectedBrand
    ? promotions.filter(promo => promo.brand === selectedBrand)
    : promotions;

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '20px' }}>
      <h1 style={{ textAlign: 'center' }}>🎉 Exclusive Flash Sales: Up to 60% Off Today! 🎉</h1>
      
      <div style={{ display: 'flex', justifyContent: 'center', margin: '20px 0' }}>
        {brands.map((brand) => (
          <Button key={brand.brand_id} onClick={() => setSelectedBrand(brand.brand_name)}>
            {brand.brand_name}
          </Button>
        ))}
        <Button onClick={() => setSelectedBrand('')}>All Brands</Button>
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center' }}>
        {filteredPromotions.map((promo) => (
          <Card key={promo.id} title={promo.brand}>
            <p>{promo.title}</p>
            <p>{promo.type}</p>
            <p>Start: {new Date(promo.startDate).toLocaleDateString()}</p>
            <p>End: {new Date(promo.endDate).toLocaleDateString()}</p>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default DiscountApp;