import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json(
    { 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      service: 'yantech-ynp01-frontend'
    },
    { status: 200 }
  );
}
