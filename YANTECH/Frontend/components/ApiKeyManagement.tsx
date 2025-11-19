import { ApiKey } from '@/types';
import React, { useState } from 'react';

interface ComponentProps {
  handleGenerateNewKey: () => void;
}

const initialKeys: ApiKey[] = [
  {
    id: "key_1a2b3c4d5e",
    name: "Production Server",
    created: "2024-01-15T10:30:00Z",
    expiry: "2025-01-15T10:30:00Z",
    isRevoked: false,
    createdDate: "2024-01-15"
  },
  {
    id: "key_9f8e7d6c5b",
    name: "Mobile App",
    created: "2024-02-20T14:45:00Z",
    expiry: "2024-08-20T14:45:00Z",
    isRevoked: true,
    createdDate: "2024-02-20"
  },
  {
    id: "key_6g5h4i3j2k",
    name: "Testing Environment",
    created: "2024-03-10T09:15:00Z",
    expiry: "2024-09-10T09:15:00Z",
    isRevoked: false,
    createdDate: "2024-03-10"
  },
  {
    id: "key_1l2m3n4o5p",
    name: "Third Party Integration",
    created: "2024-04-05T16:20:00Z",
    expiry: "2024-10-05T16:20:00Z",
    isRevoked: false,
    createdDate: "2024-04-05"
  }
];

const ApiKeyManagement: React.FC<ComponentProps> = ({handleGenerateNewKey}) => {
  // Mock data to simulate key status and deletable keys
  const [currentKeys, setCurrentKeys] = useState<ApiKey[]>(initialKeys);
  const [deletableKeys, setDeletableKeys] = useState<string[]>(['Kcdys', '12345', '12axys']);
  const [selectedKeys, setSelectedKeys] = useState<string[]>([]);

  // Styles for the cards
  const cardStyle: React.CSSProperties = {
    background: 'white',
    borderRadius: '12px',
    padding: '25px',
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.05)',
    marginBottom: '20px',
  };

  // Styles for the active/revoked indicators
  const statusIndicatorStyle = (isRevoked: boolean): React.CSSProperties => ({
    color: isRevoked ? 'red' : 'green',
    marginRight: '10px',
    fontWeight: 'bold',
  });

  // Handle key selection for deletion
  const handleSelectKey = (keyId: string) => {
    setSelectedKeys(prev => 
      prev.includes(keyId)
        ? prev.filter(id => id !== keyId)
        : [...prev, keyId]
    );
  };

  

  // Handle deletion/revocation (simulated)
  const handleDeleteSelected = () => {
    const [newKeyName, setNewKeyName] = useState('');
    if (selectedKeys.length === 0) return;
    
    // Simulate API call to delete/revoke keys
    setDeletableKeys(deletableKeys.filter(id => !selectedKeys.includes(id)));
    setCurrentKeys(currentKeys.map(key => ({
        ...key, 
        isRevoked: selectedKeys.includes(key.id) ? true : key.isRevoked
    })));
    
    setSelectedKeys([]);
    alert(`Keys ${selectedKeys.join(', ')} revoked/deleted.`);
  };
  
  // 1. Functionality to Delete/Revoke a Key
  const handleDeleteKey = (keyId: string) => {
    // In a real app, this would be an API call to revoke the key
    setCurrentKeys(currentKeys.filter(key => key.id !== keyId));
    alert(`Key ${keyId} revoked.`);
  };

  return (
    <div style={{ background: '#f4f7f9', padding: '40px', minHeight: '100vh', fontFamily: 'Arial, sans-serif' }}>
      
      {/* Create New API Key Section
      <div style={cardStyle}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: '0', fontSize: '1.2em' }}>Create New API Key</h2>
          <button 
            onClick={handleGenerateNewKey}
            style={{ padding: '8px 15px', background: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}
          >
            Generate New Key
          </button>
        </div>
        <div style={{ marginTop: '20px' }}>
          <input
            type="text"
            placeholder="Key Name"
            value={newKeyName}
            onChange={(e) => setNewKeyName(e.target.value)}
            style={{ width: '100%', padding: '10px', borderRadius: '5px', border: '1px solid #ccc', boxSizing: 'border-box', marginBottom: '10px' }}
          />
          <button 
            onClick={handleGenerateNewKey}
            style={{ width: '100%', padding: '10px', background: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}
          >
            Generate New Key
          </button>
        </div>
      </div> */}

      {/* Current API Key Status Section */}
      <div style={cardStyle}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: 'pointer' }}>
          <h2 style={{ margin: '0', fontSize: '1.2em' }}>Current API Key Status</h2>
          <button 
            onClick={handleGenerateNewKey}
            style={{ padding: '8px 15px', background: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}
          >
            Generate New Key
          </button>
        </div>
        
      {currentKeys.length === 0 ? (
        <p>No active API keys.</p>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '20px' }}>
          <thead>
            <tr style={{ background: '#f0f0f0' }}>
              <th style={{ border: '1px solid #ddd', padding: '10px', textAlign: 'left' }}>Key Name</th>
              <th style={{ border: '1px solid #ddd', padding: '10px', textAlign: 'left' }}>Key ID</th>
              <th style={{ border: '1px solid #ddd', padding: '10px', textAlign: 'left' }}>Created Date</th>
              <th style={{ border: '1px solid #ddd', padding: '10px', textAlign: 'left' }}>Expiry Date</th>
              <th style={{ border: '1px solid #ddd', padding: '10px', textAlign: 'left' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {currentKeys.map((key) => (
              <tr key={key.id}>
                <td style={{ border: '1px solid #ddd', padding: '10px' }}>{key.name}</td>
                <td style={{ border: '1px solid #ddd', padding: '10px', fontFamily: 'monospace' }}>{key.id}</td>
                <td style={{ border: '1px solid #ddd', padding: '10px' }}>{key.created}</td>
                <td style={{ border: '1px solid #ddd', padding: '10px' }}>{key.expiry}</td>
                <td style={{ border: '1px solid #ddd', padding: '10px' }}>
                  <button onClick={() => handleDeleteKey(key.id)} style={{ color: 'red', cursor: 'pointer' }}>
                    Revoke/Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      </div>

      
    </div>
  );
};

export default ApiKeyManagement;