"use client";

import { useEffect, useState } from 'react';
import api from '../lib/api';
import { X } from 'lucide-react';

interface Photo {
    id: string;
    url: string;
    filename: string;
    createdAt: string;
}

export default function Feed({ keyProp }: { keyProp: number }) {
    const [photos, setPhotos] = useState<Photo[]>([]);
    const [selectedPhoto, setSelectedPhoto] = useState<Photo | null>(null);

    useEffect(() => {
        api.get('/photos').then((res) => {
            setPhotos(res.data || []);
        });
    }, [keyProp]);

    return (
        <>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                {photos.length === 0 && <p className="text-gray-500 col-span-full text-center">No photos yet.</p>}
                {photos.map((photo) => (
                    <div
                        key={photo.id}
                        className="relative group overflow-hidden rounded-lg shadow-md aspect-square bg-gray-200 cursor-pointer"
                        onClick={() => setSelectedPhoto(photo)}
                    >
                        <img
                            src={photo.url}
                            alt={photo.filename}
                            className="object-cover w-full h-full transform transition-transform duration-300 group-hover:scale-110"
                        />
                    </div>
                ))}
            </div>

            {selectedPhoto && (
                <div
                    className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-90 p-4"
                    onClick={() => setSelectedPhoto(null)}
                >
                    <button
                        className="absolute top-4 right-4 text-white hover:text-gray-300 focus:outline-none"
                        onClick={(e) => {
                            e.stopPropagation();
                            setSelectedPhoto(null);
                        }}
                    >
                        <X size={32} />
                    </button>
                    <img
                        src={selectedPhoto.url}
                        alt={selectedPhoto.filename}
                        className="max-w-full max-h-screen object-contain"
                        onClick={(e) => e.stopPropagation()}
                    />
                </div>
            )}
        </>
    );
}
// 