"use client";

import { useEffect, useState } from 'react';
import api from '../lib/api';

interface Photo {
    id: string;
    url: string;
    filename: string;
    createdAt: string;
}

export default function Feed({ keyProp }: { keyProp: number }) {
    const [photos, setPhotos] = useState<Photo[]>([]);

    useEffect(() => {
        api.get('/photos').then((res) => {
            setPhotos(res.data || []);
        });
    }, [keyProp]);

    return (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            {photos.length === 0 && <p className="text-gray-500 col-span-full text-center">No photos yet.</p>}
            {photos.map((photo) => (
                <div key={photo.id} className="relative group overflow-hidden rounded-lg shadow-md aspect-square bg-gray-200">
                    <img
                        src={photo.url}
                        alt={photo.filename}
                        className="object-cover w-full h-full transform transition-transform duration-300 group-hover:scale-110"
                    />
                </div>
            ))}
        </div>
    );
}
